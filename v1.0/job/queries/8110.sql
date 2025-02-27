WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        c.kind AS company_type, 
        a.name AS actor_name, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as rank
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_type c ON mc.company_type_id = c.id
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name a ON ci.person_id = a.person_id
    WHERE t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT title, production_year, company_type, actor_name
    FROM RankedMovies
    WHERE rank <= 5
)
SELECT 
    production_year, 
    ARRAY_AGG(actor_name) AS top_actors, 
    STRING_AGG(DISTINCT company_type, ', ') AS production_companies
FROM TopMovies
GROUP BY production_year
ORDER BY production_year DESC;
