WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 3  -- Restrict the depth of the hierarchy
)

SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    SUM(CASE WHEN cc.kind = 'Main' THEN 1 ELSE 0 END) AS main_cast_count,
    MAX(mh.level) AS movie_depth
FROM
    cast_info c
JOIN
    aka_name a ON a.person_id = c.person_id
JOIN
    aka_title t ON t.id = c.movie_id
LEFT JOIN
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN
    keyword kw ON kw.id = mk.keyword_id
LEFT JOIN
    complete_cast cc ON cc.movie_id = t.id AND cc.subject_id = c.person_id
JOIN 
    movie_hierarchy mh ON mh.movie_id = t.id
WHERE 
    t.production_year >= 2000
    AND a.name IS NOT NULL
GROUP BY
    a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT c.movie_id) > 1
ORDER BY 
    main_cast_count DESC, movie_depth ASC
LIMIT 100;

### Explanation of the Query Components:

1. **Recursive CTE (`movie_hierarchy`)**:
   - Fetches movies produced from the year 2000 onwards and establishes a hierarchy based on linked movies (only up to three levels deep).

2. **Main SELECT Statement**:
   - Retrieves actor names, associated movie titles, production years, and aggregates keywords associated with each movie.
   - Utilizes `STRING_AGG` to concatenate distinct keywords for each movie.

3. **Conditional Aggregation**:
   - Employs a `SUM` with a `CASE` clause to count the number of 'Main' roles actors have in movies.

4. **Left Joins**:
   - Handles optional relationships, such as `movie_keyword` and `complete_cast`.

5. **Filtering**:
   - Ensures only actors associated with movies produced from 2000 and where the actor names are not `NULL` are included.

6. **Aggregation and Grouping**:
   - The query groups by actor names and movie details, allowing for accurate counting and aggregation within the `HAVING` clause.

7. **Ordering**:
   - Orders results primarily by the count of main roles and secondarily by the movie depth.

8. **Limits**:
   - Restricts the result set to 100 records for benchmarking performance. 

This elaborate query showcases many SQL features while being suitable for performance monitoring scenarios.
