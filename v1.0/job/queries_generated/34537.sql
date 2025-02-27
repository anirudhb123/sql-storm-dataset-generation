WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level,
        ARRAY[mt.id] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        lt.title,
        lt.production_year,
        mh.level + 1,
        path || ml.linked_movie_id
    FROM 
        movie_link ml
    JOIN 
        title lt ON ml.linked_movie_id = lt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    COALESCE(AVG(mh.level), 0) AS avg_link_depth,
    STRING_AGG(DISTINCT mh.movie_title || ' (' || mh.production_year || ')', '; ') AS linked_movies
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
LEFT JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
WHERE 
    a.name IS NOT NULL
    AND a.name != ''
GROUP BY 
    a.id
HAVING 
    COUNT(DISTINCT c.movie_id) > 10
ORDER BY 
    movie_count DESC
LIMIT 10;

This query creates a recursive Common Table Expression (CTE) called `MovieHierarchy` to establish a hierarchy of movies linked to each other while filtering movies produced after the year 2000. It then selects the names of actors, counts their associated movies, averages the depth of linked movies, and aggregates the titles of those linked movies for actors with more than 10 distinct movies to show a detailed report. The results are ordered by the number of movies in descending order and limited to the top 10 actors.
