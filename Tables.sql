-- ===============================================================
-- Cieľ: Vytvoriť dve výsledné tabuľky:
-- 1. t_viktoria_cervenanska_project_SQL_primary_final  - dáta o mzdách a cenách v ČR
-- 2. t_viktoria_cervenanska_project_SQL_secondary_final - dáta o ďalších európskych krajinách
-- ===============================================================


-- ===============================================================
-- 1) PRIMÁRNA TABUĽKA – MZDY A CENY POTRAVÍN V ČR
-- ===============================================================

DROP TABLE IF EXISTS t_viktoria_cervenanska_project_SQL_primary_final;

CREATE TABLE t_viktoria_cervenanska_project_SQL_primary_final AS
SELECT 
    p.payroll_year AS rok,          -- rok mzdy (a zároveň rok ceny, spájaný podľa roku)
    i.name AS odvetvie,             -- názov odvetvia (napr. priemysel, služby, atď.)
    ROUND(AVG(p.value)::numeric, 2) AS priemerna_mzda,   -- priemerná hrubá mzda v danom odvetví
    cpc.name AS potravina,          -- názov kategórie potraviny (napr. chlieb, mlieko, atď.)
    ROUND(AVG(cp.value)::numeric, 2) AS priemerna_cena,  -- priemerná cena danej potraviny v danom roku
    cpc.price_unit AS jednotka      -- jednotka ceny (napr. Kč/kg, Kč/l)
FROM czechia_payroll p
JOIN czechia_payroll_industry_branch i 
    ON p.industry_branch_code = i.code
JOIN czechia_price cp 
    ON EXTRACT(YEAR FROM cp.date_from) = p.payroll_year  -- zabezpečí spoločné roky medzi mzdami a cenami
JOIN czechia_price_category cpc 
    ON cp.category_code = cpc.code
WHERE p.value_type_code = 5958      -- priemerná hrubá mesačná mzda
  AND p.calculation_code = 100      -- priemer
  AND p.industry_branch_code IS NOT NULL  -- ignorujeme riadky bez priradeného odvetvia
GROUP BY 
    p.payroll_year, 
    i.name, 
    cpc.name, 
    cpc.price_unit
ORDER BY 
    p.payroll_year, 
    i.name, 
    cpc.name;


-- ===============================================================
-- SEKUNDÁRNA TABUĽKA – EURÓPSKE ŠTÁTY (HDP, GINI, POPULÁCIA, DLŽKA ŽIVOTA)
--     Údaje sú obmedzené na to isté obdobie rokov, ktoré sa nachádzajú
--     v primárnej tabuľke (rokový rozsah pre ČR).
-- ===============================================================

DROP TABLE IF EXISTS t_viktoria_cervenanska_project_SQL_secondary_final;

CREATE TABLE t_viktoria_cervenanska_project_SQL_secondary_final AS
WITH roky_cr AS (
    -- Získame roky, ktoré sa vyskytujú v primárnej tabuľke
    SELECT DISTINCT rok
    FROM t_viktoria_cervenanska_project_SQL_primary_final
),
ekonomika AS (
    -- Základné ekonomické ukazovatele (HDP, GINI) + medziročný rast HDP
    SELECT 
        e.country,
        e.year,
        e.gdp AS hdp,
        e.gini AS gini_koeficient,
        ROUND(
            (
                (e.gdp - LAG(e.gdp) OVER (PARTITION BY e.country ORDER BY e.year))
                / LAG(e.gdp) OVER (PARTITION BY e.country ORDER BY e.year) * 100
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
FROM ekonomika ek
JOIN roky_cr r ON ek.year = r.rok       -- Obmedzenie na rovnaké roky ako v ČR
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

