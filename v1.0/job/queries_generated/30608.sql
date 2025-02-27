WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    AVG(mh.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT mt.title, ', ') AS movie_titles,
    CASE
        WHEN COUNT(DISTINCT mh.movie_id) > 5 THEN 'Prolific Actor'
        ELSE 'Occasional Actor'
    END AS actor_status
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget' LIMIT 1)
LEFT JOIN 
    company_name cn ON ci.movie_id = cn.imdb_id
WHERE 
    ak.name IS NOT NULL
    AND mh.depth = 0
    AND (mi.info IS NULL OR mi.info::numeric > 1000000)  -- Filter for movies with Budget > 1,000,000 or without Budget info
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 1
ORDER BY 
    total_movies DESC;

This query:

1. Utilizes a recursive Common Table Expression (CTE) to construct a hierarchy of movies linked to each other starting with those produced in or after the year 2000.
2. Joins the `aka_name`, `cast_info`, and the recursive `movie_hierarchy` to gather data on actors and their movies.
3. Incorporates a left join to `movie_info` to filter based on specific info type (in this case, 'Budget').
4. Implements a string aggregation to list all unique titles associated with the actors.
5. Applies conditional logic to classify actors based on their prolificacy.
6. Utilizes various functions and filters to ensure only relevant and interesting data points are returned, focusing heavily on NULL handling and advanced predicates with various aggregations.
7. Orders the final result by the total number of movies in descending order, presenting the most involved actors first. 

This query is designed for performance benchmarking by making multiple joins and aggregations, showcasing the complexity and capabilities of SQL queries against the given schema.
