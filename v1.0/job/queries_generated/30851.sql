WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1  -- Assume '1' represents a certain movie type (e.g., 'Feature')

    UNION ALL

    SELECT 
        ml.linked_movie_id, 
        lt.title, 
        lt.production_year, 
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        title lt ON ml.linked_movie_id = lt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ah.name AS actor_name, 
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    AVG(mh.depth) AS avg_depth,
    STRING_AGG(DISTINCT mh.title, ', ') AS linked_movies
FROM 
    movie_hierarchy mh
JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
JOIN 
    aka_name ah ON ci.person_id = ah.person_id
WHERE 
    specific_condition = (SELECT AVG(some_value) FROM another_table WHERE condition) 
GROUP BY 
    ah.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 3 -- More than 3 movies
ORDER BY 
    movie_count DESC
LIMIT 10
This query employs a recursive CTE to explore a hierarchy of movies linked to each other. It counts the number of movies each actor has appeared in, calculates the average depth of their linked movies, and aggregates the titles into a single string. The filtering is dynamic, using a correlated subquery, and it also ensures actors have appeared in more than a specified number of films.
