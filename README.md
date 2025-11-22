# SQL Projekt – Analýza miezd, cien potravín a makroekonomických ukazovateľov

## Úvod
Cieľom projektu je analyzovať vývoj miezd, cien základných potravín a ich dostupnosť pre obyvateľov Českej republiky. Projekt dopĺňa aj prehľad makroekonomických ukazovateľov európskych štátov, najmä HDP, GINI koeficientu a populácie.  
Výstupom sú dve finálne tabuľky a sada SQL dotazov odpovedajúcich na definované výskumné otázky.

---

# 1. Výstupné tabuľky

## 1.1 t_viktoria_cervenanska_project_SQL_primary_final
Tabuľka obsahuje:
- priemernú hrubú mzdu podľa odvetví a rokov,
- priemerné ceny potravín podľa kategórií a rokov,
- jednotky cien,
- prepojenie miezd a cien v rovnakých rokoch,
- dáta agregované na národnej úrovni.

## 1.2 t_viktoria_cervenanska_project_SQL_secondary_final
Tabuľka obsahuje:
- HDP,
- GINI koeficient,
- populáciu,
- očakávanú dĺžku života,
- dáta dostupné pre európske krajiny.

---

# 2. Mezivýsledky (průvodní listina)

## 2.1 Výskumná otázka 1  
### Rastú mzdy vo všetkých odvetviach?

### Postup:
- Agregácia priemernej mzdy podľa odvetvia a roku.
- Výpočet medziročnej zmeny pomocou `LAG()`.
- Identifikácia poklesov.

### Zistenia:
- Celkovo mzdy rastú, no nie rovnomerne.
- Poklesy sa objavili v rokoch 2009–2013 pri odvetviach ako:
  - peněžnictví a pojišťovnictví,
  - těžba a dobývání,
  - stavebnictví,
  - vzdělávání.
- Vplyv hospodárskej krízy je zjavný.

---

## 2.2 Výskumná otázka 2  
### Koľko litrov mlieka a kg chleba si možno kúpiť v prvom a poslednom roku?

### Výsledky:

| Potravina | Prvý rok (2006) | Posledný rok (2018) | Množstvo v 2006 | Množstvo v 2018 |
|-----------|------------------|----------------------|------------------|------------------|
| Chléb konzumní kmínový | 2006 | 2018 | 1261.93 | 1319.32 |
| Mléko polotučné pasterované | 2006 | 2018 | 1408.75 | 1613.53 |

### Interpretácia:
- Dostupnosť oboch základných potravín sa zvýšila.
- Mzdy rástli rýchlejšie než ceny týchto komodít.

---

## 2.3 Výskumná otázka 3  
### Ktorá potravina zdražuje najpomalšie?

### Metóda:
- Výpočet medziročných zmien cien cez `LAG()`.
- Výpočet priemernej medziročnej zmeny pre každú kategóriu.

### Top 5 najpomalšie zdražujúcich potravín:

| Potravina | Priemerný medziročný rast (%) |
|-----------|-------------------------------|
| Cukr krystalový | -1.92 |
| Rajská jablka červená kulatá | -0.74 |
| Banány žluté | 0.81 |
| Vepřová pečeně s kostí | 0.99 |
| Přírodní minerální voda uhličitá | 1.02 |

### Interpretácia:
- Cukor a rajčiny dlhodobo zlacňujú.
- Viaceré komodity majú minimálnu cenovú infláciu.

---

## 2.4 Výskumná otázka 4  
### Existuje rok, keď rast cien prevýšil rast miezd o viac než 10 p.b.?

### Zhrnutie výsledkov:
- V žiadnom roku rozdiel medzi rastom cien a rastom miezd nepresiahol hranicu 10 p.b.
- Najvyšší rozdiel bol približne 6.66 p.b. v roku 2013.

### Interpretácia:
- Rast cien potravín nikdy výrazne neohrozil reálnu kúpnu silu obyvateľstva.

---

## 2.5 Výskumná otázka 5  
### Má HDP vplyv na zmeny v mzdách a cenách potravín?

### Výsledky (ČR):

| Rok | HDP (USD) | Rast HDP (%) | Priemerná mzda | Priemerná cena |
|-----|-----------|---------------|------------------|------------------|
| 2006 | 197 470 142 753 | 6.77 | 20342.38 | 45.52 |
| 2007 | 208 469 898 850 | 5.57 | 21724.61 | 48.59 |
| 2008 | 214 070 259 127 | 2.69 | 23475.17 | 51.60 |
| 2009 | 204 100 298 391 | -4.66 | 24238.17 | 48.29 |
| 2010 | 209 069 940 963 | 2.43 | 24722.20 | 49.23 |
| 2011 | 212 750 323 790 | 1.76 | 25284.38 | 50.88 |
| 2012 | 211 080 224 602 | -0.79 | 26077.12 | 54.30 |
| 2013 | 210 983 331 025 | -0.05 | 25670.84 | 57.07 |
| 2014 | 215 755 991 069 | 2.26 | 26323.55 | 57.49 |
| 2015 | 227 381 745 549 | 5.39 | 26959.72 | 57.18 |
| 2016 | 233 151 067 380 | 2.54 | 27946.92 | 56.49 |
| 2017 | 245 202 003 265 | 5.17 | 29735.78 | 61.93 |
| 2018 | 253 045 172 103 | 3.20 | 31980.26 | 63.27 |

### Interpretácia:
- HDP silno koreluje s rastom miezd.
- Ceny potravín reagujú menej dynamicky.
- Pokles HDP v roku 2009 ovplyvnil mzdy len mierne (spomalenie rastu).

---

# 3. Informácie o kvalite dát

## 3.1 Chýbajúce hodnoty
- Niektoré európske krajiny nemajú kompletné údaje o populácii alebo dĺžke života.
- V datasets potravín môžu byť v niektorých rokoch chýbajúce záznamy pre vybrané komodity.
- Nie všetky krajiny majú dáta za rovnaké roky.

## 3.2 Nejednotnosť zdrojov
- Ceny sú regionálne, ale boli agregované.
- Názvy produktov sú jazykovo nejednotné.
- Jednotky cien sa líšia (l, kg, ks).

## 3.3 Technické obmedzenia
- Všetky výpočty medziročných zmien sú citlivé na extrémne hodnoty.
- Pri JOIN-e medzi cenami a mzdami sa používali iba spoločné roky → menší vzorka.

---

# 4. Záver projektu
Projekt umožnil:
- porovnať vývoj miezd a cien potravín v ČR,
- vyhodnotiť dostupnosť základných potravín,
- identifikovať stabilné aj volatilné kategórie,
- analyzovať vzťah medzi makroekonomikou (HDP) a reálnou kúpyschopnosťou populácie.

Dáta potvrdili rast reálnej kúpnej sily aj stabilitu cenového vývoja v porovnaní s rastom miezd.

