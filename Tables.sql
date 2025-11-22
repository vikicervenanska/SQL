-- ===============================================================
-- Vytvorenie finálnych tabuliek pre projekt
--  - t_viktoria_cervenanska_project_SQL_primary_final
--  - t_viktoria_cervenanska_project_SQL_secondary_final
-- Poznámky:
--  - SQL kľúčové slová sú veľkými písmenami.
--  - LAG() volania sú vypočítané jednorazovo v CTE (pre efektívnosť a prehľadnosť).
--  - ROUND() sa volá nad typom numeric (pridané ::numeric tam, kde treba).
--  - Ošetrenie NULL a deleniu nulou je zahrnuté.
-- ===============================================================


-- ---------------------------------------------------------------
-- 1) PRIMÁRNA TABUĽKA: mzdy a ceny potravín v ČR
--     Výstup: t_viktoria_cervenanska_project_SQL_primary_final
-- ---------------------------------------------------------------

DROP TABLE IF EXISTS t_viktoria_cervenanska_project_SQL_primary_final;

CREATE TABLE t_viktoria_cervenanska_project_SQL_primary_final AS
WITH
-- Agregácia surových priemerov na úroveň: rok + odvetvie + potravina
PRUMERY AS (
    SELECT
        p.payroll_year                                                     AS rok,
        i.name                                                             AS odvetvie,
        cpc.name                                                           AS potravina,
        cpc.price_unit                                                     AS jednotka,
        AVG(p.value)                                                       AS priemerna_mzda_raw,
        AVG(cp.value)                                                      AS priemerna_cena_raw
    FROM czechia_payroll p
    JOIN czechia_payroll_industry_branch i
        ON p.industry_branch_code = i.code
    JOIN czechia_price cp
        ON EXTRACT(YEAR FROM cp.date_from) = p.payroll_year
    JOIN czechia_price_category cpc
        ON cp.category_code = cpc.code
    WHERE p.value_type_code = 5958        -- priemerná hrubá mesačná mzda
      AND p.calculation_code = 100        -- priemer
      AND p.industry_branch_code IS NOT NULL
    GROUP BY p.payroll_year, i.name, cpc.name, cpc.price_unit
),

-- Pretypovanie / zaokrúhlenie na konečné stĺpce (numeric pre ROUND)
MZDY_PRE AS (
    SELECT
        rok,
        odvetvie,
        potravina,
        jednotka,
        ROUND(priemerna_mzda_raw::numeric, 2)  AS priemerna_mzda,
        ROUND(priemerna_cena_raw::numeric, 2)  AS priemerna_cena
    FROM PRUMERY
),

-- Vypočítame LAG pre mzdu (podľa odvetvia) a pre cenu (podľa potraviny) len raz
MZDY_LAG AS (
    SELECT
        m.*,
        LAG(m.priemerna_mzda) OVER (PARTITION BY m.odvetvie ORDER BY m.rok) AS predosla_mzda,
        LAG(m.priemerna_cena) OVER (PARTITION BY m.potravina ORDER BY m.rok) AS predosla_cena
    FROM MZDY_PRE m
)

SELECT
    rok,
    odvetvie,
    potravina,
    priemerna_mzda,
    priemerna_cena,
    jednotka,

    -- Počet litrov mlieka, ktoré je možné kúpiť za priemernú mzdu (ak názov potraviny zodpovedá)
    CASE
        WHEN (potravina ILIKE '%mléko%' OR potravina ILIKE '%mlieko%')
             AND priemerna_cena IS NOT NULL
             AND priemerna_cena <> 0
        THEN ROUND((priemerna_mzda / priemerna_cena)::numeric, 2)
        ELSE NULL
    END AS litry_mleka,

    -- Počet kg chleba, ktoré je možné kúpiť za priemernú mzdu (ak názov potraviny zodpovedá)
    CASE
        WHEN (potravina ILIKE '%chléb%' OR potravina ILIKE '%chlieb%')
             AND priemerna_cena IS NOT NULL
             AND priemerna_cena <> 0
        THEN ROUND((priemerna_mzda / priemerna_cena)::numeric, 2)
        ELSE NULL
    END AS kg_chleba,

    -- Medziročný rast mzdy (%) s ochranou proti NULL / deleniu nulou
    CASE
        WHEN predosla_mzda IS NULL OR predosla_mzda = 0 THEN NULL
        ELSE ROUND(((priemerna_mzda - predosla_mzda) / predosla_mzda)::numeric * 100, 2)
    END AS mzda_rocny_rust_pct,

    -- Medziročný rast ceny (%) s ochranou proti NULL / deleniu nulou
    CASE
        WHEN predosla_cena IS NULL OR predosla_cena = 0 THEN NULL
        ELSE ROUND(((priemerna_cena - predosla_cena) / predosla_cena)::numeric * 100, 2)
    END AS cena_rocny_rust_pct

FROM MZDY_LAG
ORDER BY rok, odvetvie, potravina;


-- ---------------------------------------------------------------
-- 2) SEKUNDÁRNA TABUĽKA: európske štáty (HDP, GINI, populácia, očak. dĺžka života)
--     Výstup: t_viktoria_cervenanska_project_SQL_secondary_final
-- ---------------------------------------------------------------

DROP TABLE IF EXISTS t_viktoria_cervenanska_project_SQL_secondary_final;

CREATE TABLE t_viktoria_cervenanska_project_SQL_secondary_final AS
WITH
-- Zoznam rokov, ktoré sú v primárnej tabuľke (spoločné roky porovnania)
ROKY_CR AS (
    SELECT DISTINCT rok
    FROM t_viktoria_cervenanska_project_SQL_primary_final
),

-- Základné ekonomické údaje s medziročným rastom HDP (v percentách)
EKONOMIKA_RAW AS (
    SELECT
        e.country,
        e.year,
        e.gdp AS hdp,
        e.gini AS gini_koeficient,
        -- NULLIF v denominátore ošetruje deleniu nulou; ::numeric pre ROUND
        ROUND(
            (
                (e.gdp - LAG(e.gdp) OVER (PARTITION BY e.country ORDER BY e.year))
                / NULLIF(LAG(e.gdp) OVER (PARTITION BY e.country ORDER BY e.year), 0) * 100
            )::numeric
        , 2) AS hdp_rocny_rust_pct
    FROM economies e
)

SELECT
    ek.country,
    ek.year,
    ek.hdp,
    ek.hdp_rocny_rust_pct,
    ek.gini_koeficient,
    d.population AS populacia,
    le.life_expectancy AS ocakavana_dlzka_zivota
FROM EKONOMIKA_RAW ek
JOIN ROKY_CR r
    ON ek.year = r.rok                         -- obmedzenie na roky z primárnej tabuľky
JOIN countries c
    ON ek.country::text = c.country::text
LEFT JOIN demographics d
    ON ek.country::text = d.country::text
   AND ek.year::int = d.year::int
LEFT JOIN life_expectancy le
    ON ek.country::text = le.country::text
   AND ek.year::int = le.year::int
WHERE c.continent::text = 'Europe'
ORDER BY ek.country, ek.year;
