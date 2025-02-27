WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        kind_type k ON a.kind_id = k.id
    WHERE 
        a.production_year IS NOT NULL AND k.kind LIKE 'Movie%'
),
ActorsInMovies AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        COUNT(DISTINCT c.id) AS role_count,
        COALESCE(NULLIF(STRING_AGG(DISTINCT r.role ORDER BY r.role), ''), 'No Roles') AS roles
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, ak.name
),
MovieStats AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        COALESCE(MAX(ai.role_count), 0) AS max_roles,
        COALESCE(MIN(ai.role_count), 0) AS min_roles,
        AVG(ai.role_count) AS avg_roles
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorsInMovies ai ON rm.movie_id = ai.movie_id
    GROUP BY 
        rm.movie_title, rm.production_year
)
SELECT 
    ms.movie_title,
    ms.production_year,
    'Roles Min: ' || ms.min_roles || ', Avg: ' || ROUND(ms.avg_roles, 2) || ', Max: ' || ms.max_roles AS role_summary,
    CASE 
        WHEN ms.max_roles = 0 THEN 'No Cast'
        WHEN ms.avg_roles > 5 THEN 'Star-studded Cast'
        ELSE 'Moderate Cast'
    END AS cast_quality
FROM 
    MovieStats ms
WHERE 
    ms.production_year BETWEEN 1990 AND 2020
ORDER BY 
    ms.production_year DESC, ms.max_roles DESC
LIMIT 10;

SELECT 
    DISTINCT ON (ai.actor_name) 
    ai.actor_name, 
    a.title AS movie_title,
    COUNT(c.movie_id) OVER (PARTITION BY ai.actor_name) AS movies_starred
FROM 
    ActorsInMovies ai
JOIN 
    aka_title a ON ai.movie_id = a.id
ORDER BY 
    ai.actor_name, movies_starred DESC
HAVING 
    COUNT(c.movie_id) > 3;

SELECT 
    'Total Movies: ' || COUNT(*) AS total_movies,
    'Distinct Actors: ' || COUNT(DISTINCT ak.person_id) AS distinct_actors
FROM 
    aka_title a
LEFT JOIN 
    cast_info c ON a.id = c.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
WHERE 
    a.production_year IS NOT NULL AND 
    ak.name IS NOT NULL AND 
    ak.name NOT LIKE '%Test%' AND 
    ak.name NOT ILIKE '%duplicate%'
HAVING 
    COUNT(DISTINCT ak.person_id) > 0
WITH ROLLUP;
