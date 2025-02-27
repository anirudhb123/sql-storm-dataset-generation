WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id, 
        a.title, 
        a.production_year, 
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
)

SELECT 
    ah.name AS actor_name,
    COUNT(DISTINCT mv.movie_id) AS movies_involved,
    AVG(mv.depth) AS avg_depth,
    STRING_AGG(DISTINCT at.title, ', ') AS titles
FROM 
    aka_name ah
JOIN 
    cast_info ci ON ah.person_id = ci.person_id
JOIN 
    MovieHierarchy mv ON ci.movie_id = mv.movie_id
LEFT JOIN 
    aka_title at ON mv.movie_id = at.id 
WHERE 
    ah.name IS NOT NULL
    AND mv.production_year IS NOT NULL
GROUP BY 
    ah.name
HAVING 
    COUNT(DISTINCT mv.movie_id) > 1
ORDER BY 
    movies_involved DESC, 
    actor_name ASC
LIMIT 10;

-- Additional performance metrics
EXPLAIN ANALYZE
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id, 
        a.title, 
        a.production_year, 
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
)

SELECT 
    ah.name AS actor_name,
    COUNT(DISTINCT mv.movie_id) AS movies_involved,
    AVG(mv.depth) AS avg_depth,
    STRING_AGG(DISTINCT at.title, ', ') AS titles
FROM 
    aka_name ah
JOIN 
    cast_info ci ON ah.person_id = ci.person_id
JOIN 
    MovieHierarchy mv ON ci.movie_id = mv.movie_id
LEFT JOIN 
    aka_title at ON mv.movie_id = at.id 
WHERE 
    ah.name IS NOT NULL
    AND mv.production_year IS NOT NULL
GROUP BY 
    ah.name
HAVING 
    COUNT(DISTINCT mv.movie_id) > 1
ORDER BY 
    movies_involved DESC, 
    actor_name ASC;

This query uses a recursive Common Table Expression (CTE) to build a hierarchy of movies starting from those produced after the year 2000. It then collects actor names, counting their unique movie involvements and calculating the average depth of their linked movies. The results are refined with various JOINs, including a LEFT JOIN to pull related titles, and a HAVING clause to filter results to actors involved in multiple films, ultimately limited to the top 10 by unique movie count. The query also uses `EXPLAIN ANALYZE` to benchmark performance.
