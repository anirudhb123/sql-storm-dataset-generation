WITH RECURSIVE actor_hierarchy AS (
    SELECT ci.person_id, a.name AS actor_name, 0 AS depth
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    WHERE ci.movie_id IS NOT NULL

    UNION ALL

    SELECT ci.person_id, a.name AS actor_name, depth + 1
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN actor_hierarchy ah ON ci.movie_id IN (
        SELECT movie_id 
        FROM cast_info 
        WHERE person_id = ah.person_id
    )
    WHERE ci.movie_id IS NOT NULL
),

ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS movie_rank,
        COUNT(ci.person_id) AS cast_count
    FROM title t
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    GROUP BY t.title, t.production_year
),

company_overview AS (
    SELECT
        c.name AS company_name,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT mc.movie_id) AS total_movies
    FROM company_name c
    LEFT JOIN movie_companies mc ON c.id = mc.company_id
    LEFT JOIN movie_keyword mk ON mc.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY c.name
)

SELECT
    a.actor_name,
    COUNT(DISTINCT rm.title) AS total_movies,
    AVG(rm.cast_count) AS avg_cast_count,
    co.company_name,
    co.total_movies,
    COALESCE(NULLIF(MIN(rm.production_year), 0), 'N/A') AS first_year
FROM actor_hierarchy a
LEFT JOIN ranked_movies rm ON a.movie_id IN (
    SELECT movie_id
    FROM cast_info ci
    WHERE ci.person_id = a.person_id
)
LEFT JOIN company_overview co ON rm.production_year = co.total_movies
GROUP BY a.actor_name, co.company_name
HAVING COUNT(DISTINCT rm.title) > 5
ORDER BY avg_cast_count DESC, total_movies DESC;
