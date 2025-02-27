WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.id AS cast_id,
        a.name AS actor_name,
        rt.role AS role_name,
        co.name AS company_name,
        COUNT(DISTINCT kw.keyword) AS keyword_count
    FROM title t
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.id
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN role_type rt ON ci.role_id = rt.id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name co ON mc.company_id = co.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    WHERE t.production_year BETWEEN 2000 AND 2023
    AND co.country_code = 'USA'
    GROUP BY t.id, a.id, rt.id, co.id
), RankedMovies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.actor_name,
        md.role_name,
        md.company_name,
        md.keyword_count,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.keyword_count DESC) AS rank
    FROM MovieDetails md
)
SELECT 
    rm.production_year,
    STRING_AGG(rm.movie_title || ' (' || rm.role_name || ' by ' || rm.actor_name || ' - ' || rm.company_name || ')', '; ') AS movie_details
FROM RankedMovies rm
WHERE rm.rank <= 5
GROUP BY rm.production_year
ORDER BY rm.production_year DESC;
