-- ===============================================================
-- VÝSKUMNÉ OTÁZKY – DOTAZY NAD FINÁLNYMI TABUĽKAMI
-- Tabuľky:
--   t_viktoria_cervenanska_project_SQL_primary_final   (ČR - mzdy a ceny)
--   t_viktoria_cervenanska_project_SQL_secondary_final (Európske krajiny)
-- ===============================================================


-- ===============================================================
-- 1) RASTÚ V PRIEBEHU ROKOV MZDY VO VŠETKÝCH ODVETVIACH,
--    ALEBO V NIEKTORÝCH KLESAJÚ?
-- 
-- Logika:
-- - Najprv zjednodušíme dáta na úroveň: rok + odvetvie + priemerná mzda
--   (naprieč potravinami).
-- - Potom spočítame medziročný rast mzdy pre každé odvetvie.
-- - Výsledok: tabuľka s medziročným rastom mzdy v % pre každé odvetvie a rok.
-- ===============================================================

WITH mzdy_agg AS (
    SELECT 
        rok,
        odvetvie,
        AVG(priemerna_mzda) AS priemerna_mzda
    FROM t_viktoria_cervenanska_project_SQL_primary_final
    GROUP BY rok, odvetvie
),
rast_miezd AS (
    SELECT 
        odvetvie,
        rok,
        ROUND(priemerna_mzda, 2) AS priemerna_mzda,
        LAG(ROUND(priemerna_mzda, 2)) OVER (PARTITION BY odvetvie ORDER BY rok) AS predosla_mzda,
        ROUND(
            (
                priemerna_mzda 
                - LAG(priemerna_mzda) OVER (PARTITION BY odvetvie ORDER BY rok)
            )
            / LAG(priemerna_mzda) OVER (PARTITION BY odvetvie ORDER BY rok) * 100
        , 2) AS medzirocny_rast_miezd_percent
    FROM mzdy_agg
)
SELECT *
FROM rast_miezd
ORDER BY odvetvie, rok;

-- Ak chceš vidieť len odvetvia, kde mzdy niekedy klesli, môžeš spustiť:
-- SELECT * FROM rast_miezd WHERE medzirocny_rast_miezd_percent < 0;


-- ===============================================================
-- 2) KOĽKO LITROV MLIEKA A KILOGRAMOV CHLEBA SI MOŽNO KÚPIŤ
--    V PRVOM A POSLEDNOM SPOLOČNOM OBDOBÍ?
--
-- Logika:
-- - Najprv zistíme prvý a posledný rok v primárnej tabuľke.
-- - Zjednodušíme dáta na: rok + potravina + priemerná mzda + priemerná cena
--   (naprieč odvetviami).
-- - Potom pre vybrané potraviny (chlieb, mlieko) spočítame:
--     priemerná mzda / priemerná cena = množstvo, ktoré je možné kúpiť.
-- ===============================================================

WITH roky AS (
    SELECT 
        MIN(rok) AS prvy_rok,
        MAX(rok) AS posledny_rok
    FROM t_viktoria_cervenanska_project_SQL_primary_final
),
agreg AS (
    SELECT 
        rok,
        potravina,
        AVG(priemerna_mzda) AS priemerna_mzda,
        AVG(priemerna_cena) AS priemerna_cena
    FROM t_viktoria_cervenanska_project_SQL_primary_final
    GROUP BY rok, potravina
)
SELECT 
    a1.potravina,
    r.prvy_rok,
    r.posledny_rok,
    ROUND(a1.priemerna_mzda / a1.priemerna_cena, 2) AS mnozstvo_v_prvom_roku,
    ROUND(a2.priemerna_mzda / a2.priemerna_cena, 2) AS mnozstvo_v_poslednom_roku
FROM roky r
JOIN agreg a1 
    ON a1.rok = r.prvy_rok
JOIN agreg a2 
    ON a2.rok = r.posledny_rok
   AND a1.potravina = a2.potravina
WHERE a1.potravina IN (
    'Chléb konzumní kmínový',
    'Mléko polotučné pasterované'
)
ORDER BY a1.potravina;


-- ===============================================================
-- 3) KTORÁ KATEGÓRIA POTRAVÍN ZDRAŽUJE NAJPOMALŠIE
--    (NAJNIŽŠÍ PRIEMERNÝ MEDZIROČNÝ PERCENTUÁLNY NÁRAST CENY)?
--
-- Logika:
-- - Zjednodušíme dáta na: rok + potravina + priemerná cena.
-- - Vypočítame medziročnú zmenu ceny pre každú potravinu.
-- - Z týchto medziročných zmien spravíme priemer pre každú potravinu.
-- - Výsledok: potraviny zoradené od najnižšieho priemerného rastu (najpomalšie zdražovanie).
-- ===============================================================

WITH ceny_agg AS (
    SELECT 
        rok,
        potravina,
        AVG(priemerna_cena) AS priemerna_cena
    FROM t_viktoria_cervenanska_project_SQL_primary_final
    GROUP BY rok, potravina
),
medzirocne_zmeny AS (
    SELECT 
        potravina,
        rok,
        priemerna_cena,
        LAG(priemerna_cena) OVER (PARTITION BY potravina ORDER BY rok) AS predosla_cena
    FROM ceny_agg
)
SELECT 
    potravina,
    ROUND(AVG((priemerna_cena - predosla_cena) / predosla_cena * 100), 2) 
        AS priemerny_medzirocny_rast_ceny_percent
FROM medzirocne_zmeny
WHERE predosla_cena IS NOT NULL
GROUP BY potravina
ORDER BY priemerny_medzirocny_rast_ceny_percent ASC
LIMIT 10;  

-- ===============================================================
-- 4) EXISTUJE ROK, V KTOROM BOL MEDZIROČNÝ NÁRAST CIEN POTRAVÍN
--    VÝRAZNE VYŠŠÍ AKO RAST MIEZD (VIAC AKO O 10 PERCENTNÝCH BODOV)?
--
-- Logika:
-- - Spočítame priemernú mzdu za rok naprieč všetkými odvetviami a potravinami.
-- - Spočítame priemernú cenu za rok naprieč všetkými potravinami a odvetviami.
-- - Z toho medziročné % zmeny (rast miezd, rast cien).
-- - Potom hľadáme roky, kde (rast cien - rast miezd) > 10 percentuálnych bodov.
-- ===============================================================

WITH rast_miezd AS (
    -- Priemerná mzda za rok naprieč všetkými odvetviami a potravinami
    SELECT 
        rok, 
        AVG(priemerna_mzda) AS avg_mzda
    FROM t_viktoria_cervenanska_project_SQL_primary_final
    GROUP BY rok
),
rast_cien AS (
    -- Priemerná cena za rok naprieč všetkými potravinami a odvetviami
    SELECT 
        rok, 
        AVG(priemerna_cena) AS avg_cena
    FROM t_viktoria_cervenanska_project_SQL_primary_final
    GROUP BY rok
),
medzirocne_rasty AS (
    -- Spočítame medziročný % rast miezd a cien pre každý rok
    SELECT 
        r2.rok,
        ((r2.avg_cena - r1.avg_cena) / r1.avg_cena * 100) AS rast_cien_percent,
        ((m2.avg_mzda - m1.avg_mzda) / m1.avg_mzda * 100) AS rast_miezd_percent
    FROM rast_cien r1
    JOIN rast_cien r2 ON r2.rok = r1.rok + 1
    JOIN rast_miezd m1 ON m1.rok = r1.rok
    JOIN rast_miezd m2 ON m2.rok = r2.rok
)
SELECT 
    rok,
    ROUND(rast_cien_percent, 2) AS rast_cien_percent,
    ROUND(rast_miezd_percent, 2) AS rast_miezd_percent,
    ROUND(rast_cien_percent - rast_miezd_percent, 2) AS rozdiel_percent,
    CASE 
        WHEN rast_cien_percent - rast_miezd_percent > 10 THEN true
        ELSE false
    END AS vyrazne_vyssi_rast_cien
FROM medzirocne_rasty
ORDER BY rok;


-- ===============================================================
-- 5) MÁ VÝŠKA HDP VPLYV NA ZMENY V MZDÁCH A CENÁCH POTRAVÍN?
--
-- Logika:
-- - Pre Česko (Czechia) spojíme tabuľku HDP s primárnou tabuľkou podľa roku.
-- - Pre každý rok vypočítame priemernú mzdu a priemernú cenu potravín.
-- - Výsledok je dataset, ktorý sa dá použiť na analýzu vzťahu:
--     HDP vs. priemerná mzda / priemerná cena (napr. v grafe alebo korelácii).
-- ===============================================================

SELECT 
    s.country,
    s.year AS rok,
    s.hdp,
    s.hdp_rocny_rust_pct,
    ROUND(AVG(p.priemerna_mzda), 2) AS priemerna_mzda,
    ROUND(AVG(p.priemerna_cena), 2) AS priemerna_cena
FROM t_viktoria_cervenanska_project_SQL_secondary_final s
JOIN t_viktoria_cervenanska_project_SQL_primary_final p
    ON s.year = p.rok
-- pokryjeme viaceré možné názvy ČR v zdrojových dátach
WHERE s.country ILIKE 'Czech%' 
GROUP BY s.country, s.year, s.hdp, s.hdp_rocny_rust_pct
ORDER BY s.year;
