WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword,
        c.name AS company_name,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name a ON ci.person_id = a.person_id
    WHERE t.production_year >= 2000
    AND c.country_code = 'USA'
)
SELECT 
    movie_title,
    production_year,
    STRING_AGG(DISTINCT keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT company_name, ', ') AS production_companies,
    STRING_AGG(DISTINCT actor_name, ', ') AS actors
FROM RankedMovies
WHERE rn = 1
GROUP BY movie_title, production_year
ORDER BY production_year DESC, movie_title;
