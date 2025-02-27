WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000 -- Starting from year 2000 for recent movies

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    mk.keyword AS movie_keyword,
    mt.title AS movie_title,
    mh.production_year,
    DENSE_RANK() OVER (PARTITION BY a.id ORDER BY mh.production_year DESC) AS recent_movies,
    COALESCE(ci.note, 'No role noted') AS role_note,
    COUNT(*) OVER (PARTITION BY a.id) AS total_movies
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON cc.movie_id = mh.movie_id
JOIN 
    cast_info ci ON ci.id = cc.subject_id
JOIN 
    aka_name a ON a.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
WHERE 
    mh.depth <= 3 AND
    (a.name ILIKE '%Smith%' OR a.name IS NULL)
ORDER BY 
    recent_movies ASC,
    a.name ASC
LIMIT 100;

### Explanation:
1. **Recursive CTE (Common Table Expression)**: `movie_hierarchy` generates a hierarchy of movies linked together, starting from the year 2000 and going up to 3 levels deep in links. This helps in tracking related movies.
  
2. **Joins**:
   - Multiple joins are performed to connect various tables, including `complete_cast`, `cast_info`, and `aka_name` to gather details about the actors and movies.
   
3. **Window Functions**: 
   - `DENSE_RANK()` is used to rank the movies based on their production year for each actor, and `COUNT()` provides the total number of movies each actor has been part of.

4. **Complicated Predicate/Expressions**: 
   - The `WHERE` clause includes conditions to limit the movies to a depth of 3 and filters actor names using a wildcard search (case-insensitive).
   - The use of `COALESCE` provides a default value if the role note is `NULL`.

5. **Outer Join**: 
   - A `LEFT JOIN` is used to include keywords associated with movies, ensuring even movies without keywords are still included in results.

6. **Ordering and Limiting**: 
   - Final results are ordered first by the recency of movies (most recent first) and then by actor names, with a limit of 100 results to keep output manageable. 

This query is designed for performance benchmarking, examining how SQL handles multiple features in a complex scenario with root-to-leaf relationships in data.
