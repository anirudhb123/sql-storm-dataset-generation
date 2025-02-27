WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id, 
        (SELECT title FROM aka_title WHERE id = ml.linked_movie_id) AS movie_title, 
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    STRING_AGG(DISTINCT mt.movie_title, ', ') AS movies,
    AVG(dense_rank() OVER (PARTITION BY ak.person_id ORDER BY mt.production_year)) AS avg_movie_depth
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = cc.movie_id
LEFT JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mt.id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
WHERE 
    k.keyword ILIKE '%action%' 
    AND ak.name IS NOT NULL
GROUP BY 
    ak.id, ak.name
HAVING 
    COUNT(DISTINCT mc.movie_id) > 5
ORDER BY 
    total_movies DESC, 
    actor_name ASC;

### Explanation:
- **Recursive CTE (`movie_hierarchy`)**: This part creates a hierarchy of movies starting from those produced after the year 2000, linking them through the `movie_link` table to their sequels or related films.
  
- **Main Query**: 
  - It selects actor names from `aka_name` and counts the number of distinct movies they acted in, while aggregating the titles of those movies into a comma-separated string.
  - A window function (`DENSE_RANK()`) is used to calculate the average movie depth relative to the hierarchy defined in the CTE.
  
- **Joins**: 
  - It makes several joins with `cast_info`, `complete_cast`, `movie_hierarchy`, and `aka_title` to knit together actors and their movie appearances.
  
- **WHERE Clause**: 
  - It filters results to include only actors who have worked in movies with an 'action' keyword and ensures that actor names are not NULL.
  
- **HAVING Clause**: 
  - It restricts the results to actors who have appeared in more than five movies.

- **ORDER BY**: 
  - Finally, the output is ordered by the total number of movies (in descending order) and then by actor names (in ascending order). 

This elaborate query showcases multiple SQL constructs and provides a comprehensive performance benchmark scenario that can be executed and adjusted as needed for testing purposes.
