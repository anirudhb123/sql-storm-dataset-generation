WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN cast_info c ON t.id = c.movie_id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.title, t.production_year
),
PopularMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keywords,
        cast_count
    FROM RankedMovies
    WHERE rn <= 5
),
ActorInfo AS (
    SELECT 
        a.name AS actor_name,
        a.person_id,
        pm.movie_id,
        pm.title,
        pm.production_year
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN PopularMovies pm ON ci.movie_id = pm.movie_id
)
SELECT 
    ai.actor_name,
    pm.title,
    pm.production_year,
    pm.keywords,
    pm.cast_count
FROM ActorInfo ai
JOIN PopularMovies pm ON ai.movie_id = pm.movie_id
ORDER BY pm.production_year DESC, ai.actor_name;
