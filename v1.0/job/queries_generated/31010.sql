WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mk.title,
        mk.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mk ON ml.linked_movie_id = mk.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    p.name AS actor_name,
    STRING_AGG(DISTINCT mh.title || ' (' || mh.level || ')', ', ') AS linked_movies,
    COUNT(DISTINCT mh.movie_id) AS num_linked_movies,
    MAX(mh.production_year) AS latest_linked_movie,
    MIN(mh.production_year) AS earliest_linked_movie,
    AVG(mh.production_year) AS avg_linked_movie_year,
    COALESCE(ai.role_id, 0) AS role_id
FROM 
    aka_name p
LEFT JOIN 
    cast_info ai ON p.person_id = ai.person_id
LEFT JOIN 
    MovieHierarchy mh ON ai.movie_id = mh.movie_id
WHERE 
    p.name IS NOT NULL
GROUP BY 
    p.name, ai.role_id
HAVING 
    COUNT(DISTINCT mh.movie_id) > 2 
ORDER BY 
    num_linked_movies DESC;

### Explanation of Key Constructs:

1. **Recursive CTE**: The `MovieHierarchy` CTE creates a hierarchy of movies. It starts from movies produced in or after 2000, then finds linked movies recursively.

2. **String Aggregation**: The `STRING_AGG` function combines titles of linked movies and includes their hierarchy level.

3. **Aggregations**: The query calculates counts, averages, and ranges for the production years of the movies linked to actors.

4. **LEFT JOINs**: It ensures all actors are included even if they have no linked movies.

5. **COALESCE**: This function handles possible NULLs in `role_id`.

6. **HAVING Clause**: Filters out actors who have less than three linked movies, requiring a minimum participation level.

7. **Ordering**: Finally, it orders the results by the number of linked movies.
