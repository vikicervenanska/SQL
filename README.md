{\rtf1\ansi\ansicpg1250\cocoartf2865
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 # Projekt: Anal\'fdza v\'fdvoja miezd a cien potrav\'edn v \uc0\u268 eskej republike\
\
**Autor:** Vikt\'f3ria \uc0\u268 ervenansk\'e1  \
\
Cie\uc0\u318 om tohto projektu je analyzova\u357  v\'fdvoj priemern\'fdch miezd v jednotliv\'fdch odvetviach v \u268 eskej republike, porovna\u357  ich s v\'fdvojom cien vybran\'fdch z\'e1kladn\'fdch potrav\'edn a zaradi\u357  tieto zistenia do \'9air\'9aieho makroekonomick\'e9ho kontextu eur\'f3pskych kraj\'edn.  \
\
V\'fdstupom s\'fa dve fin\'e1lne tabu\uc0\u318 ky v datab\'e1ze a sada SQL dotazov odpovedaj\'facich na zadan\'e9 v\'fdskumn\'e9 ot\'e1zky.\
\
---\
\
## 1. Vytvoren\'e9 tabu\uc0\u318 ky\
\
### 1.1 t_viktoria_cervenanska_project_SQL_primary_final\
\
T\'e1to tabu\uc0\u318 ka obsahuje priemern\'e9 mzdov\'e9 hodnoty a priemern\'e9 ceny potrav\'edn v \u268 eskej republike, agregovan\'e9 pod\u318 a roku a odvetvia. \'da\u269 elom je umo\'9eni\u357  porovnanie dostupnosti vybran\'fdch z\'e1kladn\'fdch potrav\'edn vzh\u318 adom na v\'fdvoj miezd v jednotliv\'fdch odvetviach.\
\
**Zrno tabu\uc0\u318 ky:** 1 riadok = kombin\'e1cia roku, odvetvia a kateg\'f3rie potraviny.  \
**Obsahuje:** rok, n\'e1zov odvetvia, priemern\'fa mzdu v danom odvetv\'ed, n\'e1zov kateg\'f3rie potraviny, priemern\'fa cenu za jednotku a jednotku.\
\
\'dadaje s\'fa filtrovan\'e9 tak, aby:\
\
- zah\uc0\u341 \u328 ali len priemern\'fa hrub\'fa mesa\u269 n\'fa mzdu (`value_type_code = 5958` a `calculation_code = 100`),\
- obsahovali iba z\'e1znamy priraden\'e9 ku konkr\'e9tnemu odvetviu,\
- boli zl\'fa\uc0\u269 en\'e9 s cenami potrav\'edn v zhodn\'fdch rokoch.\
\
### 1.2 t_viktoria_cervenanska_project_SQL_secondary_final\
\
Tabu\uc0\u318 ka obsahuje makroekonomick\'e9 ukazovatele eur\'f3pskych kraj\'edn pre rovnak\'e9 roky ako prim\'e1rna tabu\u318 ka a je ur\u269 en\'e1 na porovnanie v\'fdvoja v \u268 R so zvy\'9akom Eur\'f3py. Okrem \'fadajov o HDP (vr\'e1tane medziro\u269 n\'e9ho rastu) s\'fa doplnen\'e9 aj \'fadaje o GINI koeficiente, popul\'e1cii a o\u269 ak\'e1vanej d\u314 \'9eke \'9eivota.\
\
**Zrno tabu\uc0\u318 ky:** 1 riadok = kombin\'e1cia roku a krajiny.  \
**Obsahuje:** krajina, rok, HDP, medziro\uc0\u269 n\'fd rast HDP (%), GINI koeficient, popul\'e1cia, o\u269 ak\'e1van\'e1 d\u314 \'9eka \'9eivota.\
\
D\'e1ta s\'fa filtrovan\'e9 iba na eur\'f3pske krajiny a s\'fa obmedzen\'e9 na roky, pre ktor\'e9 existuj\'fa \'fadaje aj v prim\'e1rnej tabu\uc0\u318 ke.\
\
---\
\
## 2. Pr\'e1ca s ch\'fdbaj\'facimi hodnotami\
\
V prim\'e1rnej tabu\uc0\u318 ke boli pou\'9eit\'e9 filtre a spojenia tak, aby sa zabr\'e1nilo pr\'edtomnosti ch\'fdbaj\'facich hodn\'f4t v k\u318 \'fa\u269 ov\'fdch st\u314 pcoch (rok, odvetvie, mzda, potravina, cena). Agreg\'e1cia pomocou priemeru zabezpe\u269 ila spr\'e1vnu reprezent\'e1ciu \'fadajov tam, kde existovalo viac z\'e1znamov pre rovnak\'fa kombin\'e1ciu.\
\
V sekund\'e1rnej tabu\uc0\u318 ke m\'f4\'9eu ch\'fdba\u357  hodnoty v st\u314 pcoch `popul\'e1cia` alebo `o\u269 ak\'e1van\'e1 d\u314 \'9eka \'9eivota`, ke\u271 \'9ee tak\'e9to \'fadaje nie s\'fa dostupn\'e9 pre v\'9aetky krajiny a roky v zdrojov\'fdch d\'e1tach. Tieto \'fadaje s\'fa sp\'e1jan\'e9 pomocou `LEFT JOIN`, aby sa zabr\'e1nilo strate riadkov pri anal\'fdze.\
\
---\
\
## 3. V\'fdskumn\'e9 ot\'e1zky a v\'fdsledky\
\
Samostatn\'fd SQL skript (`viktoria_cervenanska_project_SQL_queries.sql`) obsahuje dotazy, ktor\'e9 odpovedaj\'fa na nasledovn\'e9 v\'fdskumn\'e9 ot\'e1zky. Z\'e1ver z ka\'9edej ot\'e1zky je uveden\'fd ni\'9e\'9aie.\
\
### 3.1 Rast\'fa mzdy vo v\'9aetk\'fdch odvetviach?\
\
Anal\'fdza uk\'e1zala, \'9ee dlhodob\'fdm trendom je rast priemern\'fdch miezd vo v\'e4\uc0\u269 \'9aine odvetv\'ed. Av\'9aak viacer\'e9 odvetvia vykazuj\'fa medziro\u269 n\'e9 poklesy, najm\'e4 v obdobiach ekonomick\'e9ho oslabenia (napr\'edklad roky 2009 a\'9e 2013). Tak\'e9to poklesy sa objavili napr\'edklad v odvetviach \'84Pen\u283 \'9enictv\'ed a poji\'9a\u357 ovnictv\'ed\'93, \'84Stavebnictv\'ed\'93 alebo \'84T\u283 \'9eba a dob\'fdv\'e1n\'ed\'93.\
\
Z\'e1ver: mzdy rast\'fa dlhodobo, ale nie kontinu\'e1lne vo v\'9aetk\'fdch odvetviach.\
\
### 3.2 Ko\uc0\u318 ko chleba a mlieka si mo\'9eno k\'fapi\u357  za priemern\'fa mzdu?\
\
Pre dve vybran\'e9 potraviny \'96 \'84Chl\'e9b konzumn\'ed km\'ednov\'fd\'93 a \'84Ml\'e9ko polotu\uc0\u269 n\'e9 pasterovan\'e9\'93 \'96 bol porovnan\'fd po\u269 et kilogramov alebo litrov dostupn\'fdch za priemern\'fa mzdu v prvom a poslednom roku.\
\
V\'fdsledok ukazuje, \'9ee dostupnos\uc0\u357  chleba aj mlieka sa zv\'fd\'9aila: za priemern\'fa mzdu bolo v poslednom sledovanom roku mo\'9en\'e9 k\'fapi\u357  viac t\'fdchto potrav\'edn ne\'9e v prvom roku. Re\'e1lna dostupnos\u357  z\'e1kladn\'fdch potrav\'edn sa zlep\'9aila.\
\
### 3.3 Ktor\'e1 potravina zdra\'9euje najpomal\'9aie?\
\
Anal\'fdza priemern\'e9ho medziro\uc0\u269 n\'e9ho rastu ceny pre jednotliv\'e9 kateg\'f3rie potrav\'edn uk\'e1zala, \'9ee niektor\'e9 potraviny nielen\'9ee zdra\'9euj\'fa pomaly, ale ich ceny aj klesaj\'fa. Ide najm\'e4 o cukor, raj\u269 iny alebo ban\'e1ny. V porovnan\'ed s in\'fdmi potravinami tieto polo\'9eky zdra\'9euj\'fa najpomal\'9aie.\
\
### 3.4 Existuje rok, ke\uc0\u271  rast cien v\'fdrazne prev\'fd\'9ail rast miezd?\
\
Hranicu pre \'84v\'fdrazn\'e9 prev\'fd\'9aenie\'93 stanovuje zadanie na viac ne\'9e 10 percentu\'e1lnych bodov. V analyzovanom obdob\'ed nebol identifikovan\'fd \'9eiadny rok, v ktorom by rast cien potrav\'edn prev\'fd\'9ail rast miezd o viac ne\'9e 10 p. b.\
\
### 3.5 M\'e1 v\'fd\'9aka HDP vplyv na mzdy a ceny potrav\'edn?\
\
V\'fdsledky nazna\uc0\u269 uj\'fa pozit\'edvnu dlhodob\'fa s\'favislos\u357  medzi rastom HDP a rastom priemern\'fdch miezd. V rokoch poklesu HDP (napr\'edklad v roku 2009) mzdy spravidla nespadli, ale ich rast sa spomalil. Ceny potrav\'edn tie\'9e dlhodobo rast\'fa, v pr\'edpade kr\'e1tkodob\'fdch ekonomick\'fdch v\'fdkyvov s oneskoren\'edm.\
\
---\
\
## 4. Zhrnutie\
\
- Priemern\'e9 mzdy v \uc0\u268 eskej republike dlhodobo rast\'fa, ale nie vo v\'9aetk\'fdch odvetviach rovnomerne a nie v ka\'9edom roku.\
- Dostupnos\uc0\u357  z\'e1kladn\'fdch potrav\'edn, ako s\'fa chlieb a mlieko, sa za sledovan\'e9 obdobie zlep\'9aila.\
- Najpomal\'9aie zdra\'9euj\'fa potraviny ako cukor, raj\uc0\u269 iny, ban\'e1ny a \u271 al\'9aie z\'e1kladn\'e9 druhy ovocia \u269 i zeleniny.\
- Nebol n\'e1jden\'fd rok, v ktorom by rast cien potrav\'edn prev\'fd\'9ail rast miezd o viac ako 10 percentu\'e1lnych bodov.\
- V\'fdvoj HDP a v\'fdvoj miezd s\'fa dlhodobo pozit\'edvne previazan\'e9, aj ke\uc0\u271  kr\'e1tkodob\'e9 ekonomick\'e9 v\'fdkyvy m\'f4\'9eu vies\u357  k do\u269 asn\'e9mu spomaleniu rastu miezd alebo cien.\
\
T\'e1to spr\'e1va dokumentuje spracovanie d\'e1t, pou\'9eit\'e9 postupy a k\uc0\u318 \'fa\u269 ov\'e9 zistenia v r\'e1mci projektu zameran\'e9ho na dostupnos\u357  potrav\'edn a v\'fdvoj miezd v \u268 eskej republike.\
}