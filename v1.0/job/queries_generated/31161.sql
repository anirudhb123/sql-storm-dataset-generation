WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS varchar(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.id IS NOT NULL   -- Base case: Start with root movies

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1 AS level,
        CAST(mh.path || ' -> ' || m.title AS varchar(255)) AS path
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    COALESCE(aka.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    AVG(CASE WHEN mt.production_year < 2000 THEN 1 END) AS avg_movies_before_2000,
    STRING_AGG(DISTINCT mh.path, '; ') AS movie_paths
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name aka ON ci.person_id = aka.person_id
LEFT JOIN 
    aka_title mt ON mh.movie_id = mt.id
WHERE 
    ci.nr_order IS NOT NULL
GROUP BY 
    aka.name
HAVING 
    COUNT(DISTINCT mh.movie_id) >= 1
ORDER BY 
    total_movies DESC
LIMIT 10;

This SQL query retrieves the top 10 actors with the most movie roles, including movies linked to each other in a recursive manner. It computes the average number of movies they were involved in before 2000, concatenates the paths of movies in which they participated into a single string, and handles NULLs gracefully to avoid disruptions in the output. The various constructs such as recursive CTEs, string aggregation, outer joins, and grouping allow for an in-depth analysis of the data, making it suitable for performance benchmarking.
