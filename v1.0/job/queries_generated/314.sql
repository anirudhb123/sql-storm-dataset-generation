WITH RankedMovies AS (
    SELECT 
        m.title,
        m.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title m ON c.movie_id = m.movie_id
    WHERE 
        a.name IS NOT NULL AND
        m.production_year IS NOT NULL
),

ActorInfo AS (
    SELECT 
        a.person_id,
        COUNT(c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT m.title, ', ') AS movie_titles
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        aka_title m ON c.movie_id = m.movie_id
    GROUP BY 
        a.person_id
    HAVING 
        COUNT(c.movie_id) > 5
)

SELECT 
    r.title AS movie_title,
    r.production_year,
    r.actor_name,
    ai.movie_count,
    ai.movie_titles
FROM 
    RankedMovies r
LEFT JOIN 
    ActorInfo ai ON r.actor_name = ai.person_id
WHERE 
    r.year_rank <= 3 AND 
    (r.production_year BETWEEN 1990 AND 2020 OR r.actor_name IS NULL)
ORDER BY 
    r.production_year DESC, 
    ai.movie_count DESC
LIMIT 10;
