WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id as movie_id, 
        mt.title, 
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1 -- assuming 1 is for the movies

    UNION ALL

    SELECT 
        ml.linked_movie_id, 
        ak.title, 
        ak.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title ak ON ak.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT ch.movie_id) AS total_movies,
    STRING_AGG(DISTINCT th.title, ', ') AS titles,
    AVG(CASE WHEN th.production_year IS NOT NULL THEN th.production_year ELSE 0 END) AS average_production_year,
    MAX(mh.depth) AS max_depth_of_linked_movies,
    CASE 
        WHEN COUNT(DISTINCT ch.movie_id) > 10 THEN 'High Contributor'
        WHEN COUNT(DISTINCT ch.movie_id) > 5 THEN 'Medium Contributor'
        ELSE 'Low Contributor' 
    END AS contributor_level 
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
JOIN 
    aka_title th ON th.id = ci.movie_id
LEFT JOIN 
    MovieHierarchy mh ON mh.movie_id = th.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = th.id
WHERE 
    (th.production_year >= 2000 OR th.production_year IS NULL) 
    AND a.name IS NOT NULL
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT ch.movie_id) > 3
ORDER BY 
    total_movies DESC;

This query includes:

1. A recursive Common Table Expression (CTE) named `MovieHierarchy` to build a hierarchy of movies linked together.
2. Various JOINs to gather information about the cast, titles of movies, and additional movie information.
3. A combination of aggregate functions, including `COUNT`, `STRING_AGG`, `AVG`, and `MAX`, to obtain summarized data for each actor.
4. A `CASE` statement to classify performers based on their contribution.
5. Use of NULL logic in conditions to handle missing production years and actor names.
6. Filter conditions to only consider movies from the year 2000 onwards or those with NULL production years. 

This SQL will provide a comprehensive benchmark for performance while querying nested relationships across multiple tables.
