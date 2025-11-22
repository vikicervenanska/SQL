-- ===============================================================
-- VÝSKUMNÉ OTÁZKY – DOTAZY NAD FINÁLNYMI TABUĽKAMI
-- Tabuľky:
--   t_viktoria_cervenanska_project_SQL_primary_final   (ČR - mzdy a ceny)
--   t_viktoria_cervenanska_project_SQL_secondary_final (Európske krajiny)
-- ===============================================================


-- ===============================================================
-- 1) RASTÚ V PRIEBEHU ROKOV MZDY VO VŠETKÝCH ODVETVIACH,
--    ALEBO V NIEKTORÝCH KLESAJÚ?
-- Logika:
--  - Najprv agregujeme priemerné mzdy na úroveň (rok, odvetvie).
--  - Potom vypočítame predchádzajúcu hodnotu mzdy raz pomocou LAG() v CTE.
--  - Nakoniec spočítame medziročný rast (%) s ochranou proti NULL.
-- ===============================================================

WITH MZDY_AGG AS (
    SELECT
        ROK,
        ODVETVIE,
        AVG(PRIMERNA_MZDA) AS PRIEMERNA_MZDA
    FROM t_viktoria_cervenanska_project_SQL_primary_final
    GROUP BY ROK, ODVETVIE
),
MZDY_LAG AS (
    -- LAG počítame raz pre každé odvetvie
    SELECT
        ODVETVIE,
        ROK,
        PRIEMERNA_MZDA,
        LAG(PRIEMERNA_MZDA) OVER (PARTITION BY ODVETVIE ORDER BY ROK) AS PREDSLA_MZDA
    FROM MZDY_AGG
)
SELECT
    ODVETVIE,
    ROK,
    ROUND(PRIEMERNA_MZDA::NUMERIC, 2) AS PRIEMERNA_MZDA,
    ROUND(PREDSLA_MZDA::NUMERIC, 2) AS PREDSLA_MZDA,
    CASE
        WHEN PREDSLA_MZDA IS NULL OR PREDSLA_MZDA = 0 THEN NULL
        ELSE ROUND(((PRIEMERNA_MZDA - PREDSLA_MZDA) / PREDSLA_MZDA)::NUMERIC * 100, 2)
    END AS MEDZIROCNY_RST_MIEZD_PERCENT
FROM MZDY_LAG
ORDER BY ODVETVIE, ROK;


-- ===============================================================
-- 2) KOĽKO LITROV MLIEKA A KILOGRAMOV CHLEBA SI MOŽNO KÚPIŤ
--    V PRVOM A POSLEDNOM SPOLOČNOM OBDOBÍ?
-- Logika:
--  - Zistíme prvý a posledný rok.
--  - Agregujeme priemernú mzdu a priemernú cenu pre kombináciu (rok, potravina).
--  - Vypočítame pomer mzda / cena pre prvý a posledný rok.
-- ===============================================================

WITH ROKY AS (
    SELECT
        MIN(ROK) AS PRVY_ROK,
        MAX(ROK) AS POSLEDNY_ROK
    FROM t_viktoria_cervenanska_project_SQL_primary_final
),
AGREG AS (
    SELECT
        ROK,
        POTRAVINA,
        AVG(PRIMERNA_MZDA)   AS PRIEMERNA_MZDA,
        AVG(PRIMERNA_CENA)   AS PRIEMERNA_CENA
    FROM t_viktoria_cervenanska_project_SQL_primary_final
    GROUP BY ROK, POTRAVINA
)
SELECT
    A1.POTRAVINA,
    R.PRVY_ROK,
    R.POSLEDNY_ROK,
    ROUND(A1.PRIEMERNA_MZDA / NULLIF(A1.PRIEMERNA_CENA, 0), 2) AS MNOZSTVO_V_PRVOM_ROKU,
    ROUND(A2.PRIEMERNA_MZDA / NULLIF(A2.PRIEMERNA_CENA, 0), 2) AS MNOZSTVO_V_POSLEDNOM_ROKU
FROM ROKY R
JOIN AGREG A1
    ON A1.ROK = R.PRVY_ROK
JOIN AGREG A2
    ON A2.ROK = R.POSLEDNY_ROK
   AND A1.POTRAVINA = A2.POTRAVINA
WHERE A1.POTRAVINA IN (
    'Chléb konzumní kmínový',
    'Mléko polotučné pasterované'
)
ORDER BY A1.POTRAVINA;


-- ===============================================================
-- 3) KTORÁ KATEGÓRIA POTRAVÍN ZDRAŽUJE NAJPOMALŠIE
-- Logika:
--  - Agregujeme priemerné ceny na úroveň (rok, potravina).
--  - V CTE vypočítame PREDSLA_CENA pomocou LAG() len raz.
--  - Potom spočítame medziročnú zmenu (%) a z nich priemerný medziročný rast.
-- ===============================================================

WITH CENY_AGG AS (
    SELECT
        ROK,
        POTRAVINA,
        AVG(PRIMERNA_CENA) AS PRIEMERNA_CENA
    FROM t_viktoria_cervenanska_project_SQL_primary_final
    GROUP BY ROK, POTRAVINA
),
CENY_LAG AS (
    SELECT
        POTRAVINA,
        ROK,
        PRIEMERNA_CENA,
        LAG(PRIEMERNA_CENA) OVER (PARTITION BY POTRAVINA ORDER BY ROK) AS PREDSLA_CENA
    FROM CENY_AGG
),
CENY_ZMENY AS (
    SELECT
        POTRAVINA,
        ROK,
        PRIEMERNA_CENA,
        PREDSLA_CENA,
        CASE
            WHEN PREDSLA_CENA IS NULL OR PREDSLA_CENA = 0 THEN NULL
            ELSE (PRIEMERNA_CENA - PREDSLA_CENA) / PREDSLA_CENA * 100
        END AS MEDZIROCNA_ZMENA_PERCENT
    FROM CENY_LAG
)
SELECT
    POTRAVINA,
    ROUND(AVG(MEDZIROCNA_ZMENA_PERCENT)::NUMERIC, 2) AS PRIEMERNY_MEDZIROCNY_RST_CENY_PERCENT
FROM CENY_ZMENY
WHERE MEDZIROCNA_ZMENA_PERCENT IS NOT NULL
GROUP BY POTRAVINA
ORDER BY PRIEMERNY_MEDZIROCNY_RST_CENY_PERCENT ASC
LIMIT 10;


-- ===============================================================
-- 4) EXISTUJE ROK, V KTOROM BOL MEDZIROČNÝ NÁRAST CIEN POTRAVÍN
--    VÝRAZNE VYŠŠÍ AKO RAST MIEZD (VIAC AKO O 10 PERCENTNÝCH BODOV)?
-- Logika:
--  - Vypočítame priemerné ročné hodnoty pre mzdy a ceny.
--  - Pomocou JOIN medzi rokmi získame medziročné % pre oba ukazovatele.
--  - Potom spočítame rozdiel a označíme, či prekračuje 10 p.b.
-- ===============================================================

WITH RAST_MIEZD AS (
    SELECT
        ROK,
        AVG(PRIMERNA_MZDA) AS AVG_MZDA
    FROM t_viktoria_cervenanska_project_SQL_primary_final
    GROUP BY ROK
),
RAST_CIEN AS (
    SELECT
        ROK,
        AVG(PRIMERNA_CENA) AS AVG_CENA
    FROM t_viktoria_cervenanska_project_SQL_primary_final
    GROUP BY ROK
),
RASTY_PRE AS (
    -- Prepočítame medziročný rast pre mzdy a ceny raz (pomocou join R1->R2)
    SELECT
        R2.ROK AS ROK,
        (R2.AVG_CENA - R1.AVG_CENA) / NULLIF(R1.AVG_CENA, 0) * 100 AS RAST_CIEN_PERCENT,
        (M2.AVG_MZDA - M1.AVG_MZDA) / NULLIF(M1.AVG_MZDA, 0) * 100 AS RAST_MIEZD_PERCENT
    FROM RAST_CIEN R1
    JOIN RAST_CIEN R2 ON R2.ROK = R1.ROK + 1
    JOIN RAST_MIEZD M1 ON M1.ROK = R1.ROK
    JOIN RAST_MIEZD M2 ON M2.ROK = R2.ROK
)
SELECT
    ROK,
    ROUND(RAST_CIEN_PERCENT::NUMERIC, 2) AS RAST_CIEN_PERCENT,
    ROUND(RAST_MIEZD_PERCENT::NUMERIC, 2) AS RAST_MIEZD_PERCENT,
    ROUND((RAST_CIEN_PERCENT - RAST_MIEZD_PERCENT)::NUMERIC, 2) AS ROZDIEL_PERCENT,
    CASE
        WHEN (RAST_CIEN_PERCENT - RAST_MIEZD_PERCENT) > 10 THEN TRUE
        ELSE FALSE
    END AS VYRAZNE_VYSSI_RST_CIEN
FROM RASTY_PRE
ORDER BY ROK;


-- ===============================================================
-- 5) MÁ VÝŠKA HDP VPLYV NA ZMENY V MZDÁCH A CENÁCH POTRAVÍN?
-- Logika:
--  - Vyberieme údaje o HDP pre CR zo sekundárnej tabuľky (HDP + medziročný rast).
--  - Spojíme ich s priemernými mzdami a cenami z primárnej tabuľky podľa roku.
--  - Pre každý rok vypočítame priemernú mzdu a priemernú cenu.
--  - Výsledok slúži ako vstup do ďalšej analýzy (graf, korelácia).
-- ===============================================================

WITH HDP_CR AS (
    SELECT
        COUNTRY,
        YEAR,
        HDP,
        -- medziročný rast HDP počítame raz; NULLIF pre denominátor
        ROUND((
            (HDP - LAG(HDP) OVER (PARTITION BY COUNTRY ORDER BY YEAR))
            / NULLIF(LAG(HDP) OVER (PARTITION BY COUNTRY ORDER BY YEAR), 0) * 100
        )::NUMERIC, 2) AS HDP_ROCNY_RST_PCT
    FROM t_viktoria_cervenanska_project_SQL_secondary_final
    WHERE COUNTRY ILIKE 'Czech%'
),
PRIEMERNE_R AS (
    SELECT
        ROK,
        ROUND(AVG(PRIMERNA_MZDA)::NUMERIC, 2) AS PRIEMERNA_MZDA,
        ROUND(AVG(PRIMERNA_CENA)::NUMERIC, 2) AS PRIEMERNA_CENA
    FROM t_viktoria_cervenanska_project_SQL_primary_final
    GROUP BY ROK
)
SELECT
    H.COUNTRY,
    H.YEAR AS ROK,
    H.HDP,
    H.HDP_ROCNY_RST_PCT,
    P.PRIEMERNA_MZDA,
    P.PRIEMERNA_CENA
FROM HDP_CR H
JOIN PRIEMERNE_R P
    ON H.YEAR = P.ROK
ORDER BY H.YEAR;
