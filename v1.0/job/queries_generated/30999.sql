WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    AVG(mh.depth) AS average_depth,
    STRING_AGG(DISTINCT mt.title, ', ') AS movie_titles,
    MIN(mt.production_year) AS first_movie_year,
    MAX(mt.production_year) AS latest_movie_year,
    SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS acting_roles
FROM 
    aka_name ak
LEFT JOIN 
    cast_info c ON ak.person_id = c.person_id
LEFT JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    aka_title mt ON mh.movie_id = mt.id
WHERE 
    ak.name IS NOT NULL
    AND ak.name <> ''
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 0
ORDER BY 
    total_movies DESC
LIMIT 10;

This complex SQL query accomplishes several tasks:

1. **Recursive CTE (`movie_hierarchy`)**: It builds a hierarchy of movies linked through the `movie_link` table, starting from the main movie titles. The recursion allows us to gather movies that are linked to others, e.g., sequels or spin-offs.

2. **Main Select Statement**: This section aggregates data about actors (`aka_name`), counting movies they're linked to, calculating the average depth of linked movies, collecting titles into a single string, and finding the range of production years they've participated in.

3. **JOINs**: Multiple LEFT JOINs combine several tables to capture all required information about actors, their roles, and the movies.

4. **String Aggregation**: The `STRING_AGG` function collects all unique movie titles associated with each actor.

5. **Conditional Aggregation**: It uses a CASE statement to count how many acting roles exist for each actor, counting only where `role_id` is not NULL.

6. **Filtering and Grouping**: It groups results by actor name, ensuring that only actors who have worked on movies (total more than 0) are included.

7. **Ordering and Limiting**: Finally, it orders the results to show the top 10 actors with the most movies. 

The query exhibits various SQL constructs putting the JOIN Order Benchmark schema to extensive usage, demonstrating advanced SQL querying skills.
