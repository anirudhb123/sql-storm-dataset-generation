WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        0 AS level, 
        NULL::integer AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        mh.level + 1,
        mh.movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mv.title AS Main_Movie_Title,
    mv.production_year AS Year,
    COALESCE(p.name, 'Unknown') AS Actor_Name,
    COUNT(DISTINCT ml.linked_movie_id) AS Linked_Movies_Count,
    AVG(mv2.production_year) AS Avg_Linked_Year
FROM 
    aka_title mv
LEFT JOIN 
    movie_link ml ON mv.id = ml.movie_id
LEFT JOIN 
    aka_name p ON p.person_id = (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = mv.id LIMIT 1)
LEFT JOIN 
    aka_title mv2 ON ml.linked_movie_id = mv2.id
WHERE 
    mv.production_year BETWEEN 2010 AND 2023
    AND (p.name IS NULL OR p.name ILIKE 'A%')
GROUP BY 
    mv.id, mv.title, mv.production_year, p.name
HAVING 
    COUNT(DISTINCT ml.linked_movie_id) > 0
ORDER BY 
    Year DESC, Main_Movie_Title;

This SQL query is designed to benchmark the performance of various query constructs across the Joins and aggregations.

### Breakdown:
1. **CTE with Recursion (`MovieHierarchy`)**: This recursively builds a hierarchy of movies linked together, starting from movies released in 2000 onward.
2. **Main Select**: Pulls information regarding each main movie:
   - Title and production year.
   - Actor name from a correlated subquery (grabs the first associated actor's name from the `cast_info` table).
   - Counts the number of linked movies and calculates the average production year of those linked movies.
3. **LEFT JOINs**: Used to ensure even movies without links or actors show up in the results.
4. **Predicates**: Contains conditions on both the production years and applies a filter to specific actor names.
5. **NULL Logic**: Handles cases when there may be no actor's name with a fallback value of 'Unknown'.
6. **Aggregations**: Counts distinct linked movies and checks for New High-Performance Programming principles, ensuring results get further filtered.
7. **Order By**: Sorts results by year and title for clear benchmarking.

This query can be used to explore how various SQL constructs perform while allowing benchmarking scenarios across potentially large datasets.
