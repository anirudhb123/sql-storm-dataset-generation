WITH TitleInfo AS (
    SELECT t.id AS title_id, t.title, t.production_year, k.keyword
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
), 
CompleteCast AS (
    SELECT cc.movie_id, COUNT(cc.subject_id) AS total_cast
    FROM complete_cast cc
    GROUP BY cc.movie_id
), 
CompanyInfo AS (
    SELECT mc.movie_id, c.name AS company_name, ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
), 
PersonInfo AS (
    SELECT p.name AS person_name, ak.name AS aka_name, ak.id AS aka_id, ci.movie_id
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN name p ON ak.person_id = p.imdb_id
)

SELECT ti.title, ti.production_year, ci.company_name, ci.company_type, cc.total_cast,
       pi.person_name, pi.aka_name
FROM TitleInfo ti
JOIN CompanyInfo ci ON ti.title_id = ci.movie_id
JOIN CompleteCast cc ON ti.title_id = cc.movie_id
LEFT JOIN PersonInfo pi ON ti.title_id = pi.movie_id
WHERE ti.production_year >= 2000
ORDER BY ti.production_year DESC, ti.title;
