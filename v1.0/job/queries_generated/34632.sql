WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.id
),
actor_movies AS (
    SELECT 
        ci.person_id,
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY mt.production_year DESC) AS rn
    FROM 
        cast_info ci
    JOIN 
        aka_title mt ON ci.movie_id = mt.id
),
actor_info AS (
    SELECT 
        ak.name,
        am.movie_title,
        am.production_year,
        COALESCE(mh.level, 0) AS movie_level,
        COUNT(*) OVER (PARTITION BY ak.name) AS total_movies
    FROM 
        aka_name ak
    LEFT JOIN 
        actor_movies am ON ak.person_id = am.person_id AND am.rn <= 5
    LEFT JOIN 
        movie_hierarchy mh ON am.movie_id = mh.id
)
SELECT 
    ai.name AS actor_name,
    ARRAY_AGG(DISTINCT ai.movie_title) AS movies,
    AVG(ai.production_year) AS avg_production_year,
    MAX(ai.movie_level) AS max_movie_level,
    COUNT(DISTINCT ai.movie_title) AS unique_movie_count
FROM 
    actor_info ai
WHERE 
    ai.total_movies > 3
GROUP BY 
    ai.name
HAVING 
    max_movie_level > 2
ORDER BY 
    unique_movie_count DESC;
