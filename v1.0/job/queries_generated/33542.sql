WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.id AS cast_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year >= 2000
    
    UNION ALL

    SELECT 
        c.id AS cast_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    JOIN 
        actor_hierarchy ah ON c.movie_id = ah.cast_id
    WHERE 
        t.production_year >= 2000 AND ah.level < 3
)

SELECT 
    ah.actor_name,
    ah.movie_title,
    ah.production_year,
    COUNT(DISTINCT ah.cast_id) OVER (PARTITION BY ah.actor_name) AS movie_count,
    MAX(ah.production_year) OVER (PARTITION BY ah.actor_name) AS last_movie_year,
    CASE 
        WHEN MAX(ah.production_year) OVER (PARTITION BY ah.actor_name) IS NULL 
        THEN 'No movies found' 
        ELSE 'Movies found' 
    END AS movie_availability,
    COALESCE(SUM(CASE WHEN c.person_role_id IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY ah.actor_name), 0) AS roles_played
FROM 
    actor_hierarchy ah
LEFT JOIN 
    cast_info c ON ah.cast_id = c.movie_id
WHERE 
    ah.movie_title IS NOT NULL
ORDER BY 
    movie_count DESC, last_movie_year DESC
LIMIT 10;

-- Additional Benchmarking Queries

-- 1. Fetching movies with the highest number of unique actors
SELECT 
    t.title,
    COUNT(DISTINCT c.person_id) AS unique_actors
FROM 
    aka_title t
JOIN 
    cast_info c ON t.id = c.movie_id
GROUP BY 
    t.title
ORDER BY 
    unique_actors DESC
LIMIT 5;

-- 2. Finding production companies involved in highest number of movies in 2022
SELECT 
    cn.name AS company_name,
    COUNT(DISTINCT mc.movie_id) AS movies_count
FROM 
    company_name cn
JOIN 
    movie_companies mc ON cn.id = mc.company_id
JOIN 
    aka_title t ON mc.movie_id = t.id
WHERE 
    t.production_year = 2022
GROUP BY 
    cn.name
ORDER BY 
    movies_count DESC
LIMIT 5;

-- 3. Movies with highest rating from different keywords
SELECT 
    t.title,
    k.keyword,
    COUNT(mk.movie_id) AS keyword_count
FROM 
    aka_title t
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    t.title, k.keyword
ORDER BY 
    keyword_count DESC
LIMIT 5;

-- End of Benchmarking Queries

This SQL script makes use of various constructs such as Common Table Expressions (CTEs), including recursive CTEs, window functions, and outer joins to create a rich query environment suitable for performance benchmarking. Adaptations can be made to further refine or explore specific areas of interest in the schema provided.
