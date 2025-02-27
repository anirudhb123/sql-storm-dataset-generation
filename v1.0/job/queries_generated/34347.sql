WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000 -- Start from movies released in or after 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT 
    p.name AS actor_name,
    ARRAY_AGG(DISTINCT mh.title) AS movies,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    string_agg(DISTINCT ci.note, ', ') AS roles,
    SUM(CASE WHEN mt.production_year = 2023 THEN 1 ELSE 0 END) AS movies_released_2023,
    ROW_NUMBER() OVER (PARTITION BY p.id ORDER BY COUNT(DISTINCT mh.movie_id) DESC) AS role_ranking
FROM 
    cast_info ci
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_title mt ON ci.movie_id = mt.id
GROUP BY 
    p.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 1 -- Only include actors in more than one movie
ORDER BY 
    movie_count DESC, p.name;

This SQL query first establishes a recursive Common Table Expression (CTE) named `MovieHierarchy` to gather a hierarchy of movies based on their links, specifically filtering for those produced from 2000 onwards. The main body of the query subsequently analyzes data from various tables including `cast_info` and `aka_name`, aggregating key insights about actors, the movies they've appeared in, and their respective roles, while applying criteria such as counting films released in the year 2023. The results are then ordered by the number of movies associated with each actor and are filtered to include only those actors with more than one movie credit.
