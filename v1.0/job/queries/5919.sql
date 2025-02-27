
WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM title t
    JOIN movie_info mi ON t.id = mi.movie_id
    JOIN aka_title at ON t.id = at.movie_id
    JOIN cast_info c ON t.id = c.movie_id
    JOIN aka_name ak ON c.person_id = ak.person_id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE mi.info_type_id IN (
        SELECT id FROM info_type WHERE info = 'tagline'
    )
    GROUP BY t.id, t.title, t.production_year
    ORDER BY keyword_count DESC, t.production_year DESC
    LIMIT 10
)
SELECT 
    RM.movie_title,
    RM.production_year,
    RM.actor_names,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM RankedMovies RM
JOIN movie_companies mc ON RM.movie_title = (
    SELECT title FROM title WHERE id = mc.movie_id
)
GROUP BY RM.movie_title, RM.production_year, RM.actor_names
ORDER BY company_count DESC;
