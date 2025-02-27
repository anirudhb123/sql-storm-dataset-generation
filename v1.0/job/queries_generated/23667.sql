WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_within_year
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year IS NOT NULL 
        AND t.production_year BETWEEN 1990 AND 2020
), 
actor_info AS (
    SELECT 
        a.id AS actor_id,
        ak.name,
        COUNT(c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info c ON ak.person_id = c.person_id
    LEFT JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.id 
), 
high_ranking_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ai.name AS actor_name,
        ai.movie_count,
        ai.movies
    FROM 
        ranked_movies rm
    LEFT JOIN 
        cast_info c ON rm.movie_id = c.movie_id
    LEFT JOIN 
        actor_info ai ON c.person_id = ai.actor_id
    WHERE 
        rm.rank_within_year <= 5 -- top 5 movies of each year
)

SELECT 
    hr.title,
    hr.production_year,
    hr.actor_name,
    hr.movie_count,
    COALESCE(hr.movies, 'No movies listed') AS movies_listed
FROM 
    high_ranking_movies hr
WHERE 
    (hr.actor_name IS NOT NULL OR hr.actor_name IS NULL) -- Unusual NULL logic
ORDER BY 
    hr.production_year DESC, 
    hr.title;

-- The following set operators demonstrate unusual corner cases.
UNION ALL

SELECT 
    NULL AS title, 
    NULL AS production_year, 
    NULL AS actor_name,
    COUNT(DISTINCT m.id) AS movie_count, 
    'Legacy movies count' AS movies_listed
FROM 
    aka_title m
WHERE 
    m.production_year < 1990
HAVING 
    COUNT(DISTINCT m.id) > 50 
ORDER BY 
    movie_count DESC;
