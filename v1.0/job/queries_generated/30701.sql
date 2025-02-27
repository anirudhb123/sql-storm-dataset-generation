WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1 AS depth
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.movie_id = m.id
    WHERE 
        mh.depth < 3   -- limit recursion depth to 3
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COALESCE(cast_info.nr_order, 999) AS cast_order,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COALESCE(cast_info.nr_order, 999)) AS actor_rank,
    COUNT(DISTINCT mw.movie_id) OVER (PARTITION BY ak.person_id) AS movie_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    aka_name ak
JOIN 
    cast_info ON ak.person_id = cast_info.person_id
JOIN 
    aka_title at ON cast_info.movie_id = at.id
LEFT JOIN 
    movie_keyword mw ON at.id = mw.movie_id
LEFT JOIN 
    keyword kw ON mw.keyword_id = kw.id
JOIN 
    movie_hierarchy mh ON at.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
    AND at.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('feature', 'short'))
    AND at.production_year >= 2000
GROUP BY 
    ak.person_id, ak.name, at.title, at.production_year, cast_info.nr_order
HAVING 
    COUNT(DISTINCT mw.movie_id) > 5
ORDER BY 
    actor_rank, at.production_year DESC;

### Explanation:
1. **Common Table Expression (CTE)**: A recursive CTE (`movie_hierarchy`) is used to create a hierarchy of linked movies starting from those produced in or after 2000. This incorporates recursive relations up to 3 levels.

2. **Joins**: Multiple outer joins are applied to gather necessary information across different tables.
   - `JOIN` on `aka_name`, `cast_info`, and `aka_title` to get actor names and the titles of movies they are associated with.
   - `LEFT JOIN` on `movie_keyword` and `keyword` to gather all related keywords for the movies.

3. **Window Functions**: `ROW_NUMBER()` is utilized to assign a rank to each actor’s appearances based on their order in the cast for the movie.

4. **Aggregations**: `COUNT(DISTINCT mw.movie_id)` lets you count the unique movies associated with each actor. `STRING_AGG()` aggregates unique keywords into a single string.

5. **Filters**: 
   - `HAVING` clause is used to ensure only actors with more than 5 unique movie appearances are considered.
   - Adjustments in the `WHERE` clause to ensure no NULL names and filter by certain movie kinds.

6. **Ordering**: The final result set is ordered by `actor_rank` and `production_year` descending for better readability.

This query incorporates several complex SQL concepts suitable for performance benchmarking in a database environment.
