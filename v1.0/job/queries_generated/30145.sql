WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- Starting point for movies produced from year 2000

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
    ak.name AS actor_name,
    ak.pcode AS actor_pcode,
    COUNT(mh.movie_id) AS total_movies,
    AVG(mh.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT mt.title, ', ') AS all_movie_titles,
    MAX(CASE WHEN mt.production_year IS NULL THEN 'NO INFO' ELSE mt.production_year::text END) AS latest_year
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_title mt ON mh.movie_id = mt.id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name, ak.pcode
HAVING 
    COUNT(mh.movie_id) > 0
ORDER BY 
    total_movies DESC
LIMIT 10;

### Explanation:

1. **Recursive CTE (Common Table Expression)**: `MovieHierarchy` recursively builds a hierarchy of movies starting from those produced in the year 2000, including any linked movies associated with them.

2. **Main Query:**
   - **LEFT JOINs** are used to connect actors with their roles in movies, ensuring that even if an actor has not appeared in any movie, their name will still appear in the output with a movie count of zero.
   - **Aggregations** are performed to count the total movies each actor has appeared in, calculate the average production year, and aggregate all movie titles into a single string.
   - **NULL logic** is demonstrated by handling cases where `production_year` might be NULL, returning 'NO INFO' in such cases.
   - **Group By and Having Clause** ensure that only actors with at least one movie are considered.
   - Finally, results are ordered by the total number of movies appeared in, returning the top 10 actors. 

This query combines various SQL constructs which showcase complex behavior in data relationships, making it suitable for performance benchmarking.
