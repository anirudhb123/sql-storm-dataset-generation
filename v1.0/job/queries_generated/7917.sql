WITH RecursiveTitle AS (
    SELECT t.id, t.title, t.production_year, t.kind_id
    FROM title t
    WHERE t.production_year BETWEEN 2000 AND 2023
      AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv_series'))
),
CompanyDetails AS (
    SELECT cc.movie_id, c.name AS company_name, ct.kind AS company_type
    FROM movie_companies cc
    JOIN company_name c ON cc.company_id = c.id
    JOIN company_type ct ON cc.company_type_id = ct.id
),
KeywordDetails AS (
    SELECT mk.movie_id, k.keyword
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
),
CastDetails AS (
    SELECT ci.movie_id, ak.name AS actor_name, rt.role
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN role_type rt ON ci.role_id = rt.id
)
SELECT rt.title, rt.production_year, cd.company_name, cd.company_type, 
       STRING_AGG(kd.keyword, ', ') AS keywords, 
       STRING_AGG(cd.actor_name || ' as ' || cd.role, ', ') AS cast
FROM RecursiveTitle rt
LEFT JOIN CompanyDetails cd ON rt.id = cd.movie_id
LEFT JOIN KeywordDetails kd ON rt.id = kd.movie_id
LEFT JOIN CastDetails cd ON rt.id = cd.movie_id
GROUP BY rt.id, rt.title, rt.production_year, cd.company_name, cd.company_type
ORDER BY rt.production_year DESC, rt.title;
