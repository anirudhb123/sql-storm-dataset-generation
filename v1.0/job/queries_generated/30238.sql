WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        mh.level + 1 AS level
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.id = mh.movie_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE 
        mh.level < 5 -- limiting levels to prevent infinite recursion
)

SELECT 
    na.name AS actor_name,
    COUNT(DISTINCT ch.movie_id) AS total_movies,
    STRING_AGG(DISTINCT mh.keyword, ', ') AS keywords,
    AVG(mh.production_year) AS avg_production_year
FROM 
    cast_info ci 
JOIN 
    aka_name na ON ci.person_id = na.person_id
JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
JOIN 
    MovieHierarchy mh ON mh.movie_id = cc.movie_id
GROUP BY 
    na.name
HAVING 
    COUNT(DISTINCT ch.movie_id) > 5 -- actors with more than 5 movies
ORDER BY 
    total_movies DESC
LIMIT 10;

-- Performance Benchmark Query:
EXPLAIN ANALYZE 
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE 
        mt.production_year >= 2000

    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        mh.level + 1 AS level
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.id = mh.movie_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE 
        mh.level < 5 -- limiting levels to prevent infinite recursion
)

SELECT 
    na.name AS actor_name,
    COUNT(DISTINCT ch.movie_id) AS total_movies,
    STRING_AGG(DISTINCT mh.keyword, ', ') AS keywords,
    AVG(mh.production_year) AS avg_production_year
FROM 
    cast_info ci 
JOIN 
    aka_name na ON ci.person_id = na.person_id
JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
JOIN 
    MovieHierarchy mh ON mh.movie_id = cc.movie_id
GROUP BY 
    na.name
HAVING 
    COUNT(DISTINCT ch.movie_id) > 5 -- actors with more than 5 movies
ORDER BY 
    total_movies DESC
LIMIT 10;
