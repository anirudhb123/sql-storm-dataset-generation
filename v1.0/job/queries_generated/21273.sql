WITH RecursiveMovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        CAST(NULL AS TEXT) AS previous_movie_title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        cte.title AS previous_movie_title,
        cte.level + 1
    FROM 
        RecursiveMovieCTE cte
    JOIN 
        movie_link ml ON cte.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        cte.level < 5  -- limit depth to avoid infinite loops
)
SELECT 
    DISTINCT 
    ak.name AS actor_name,
    ak.name_pcode_nf AS actor_name_pcode_nf,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mh.production_year DESC) AS recent_movie_rank
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ak.person_id = ci.person_id
JOIN 
    RecursiveMovieCTE mh ON mh.movie_id = ci.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword kc ON kc.id = mk.keyword_id 
WHERE 
    mh.production_year >= 2000 
    AND (LOWER(ak.name) LIKE '%john%' OR ak.name IS NULL)
    AND EXISTS (
        SELECT 
            1
        FROM 
            title t
        WHERE 
            t.id = mh.movie_id 
            AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Feature%')
    )
GROUP BY 
    ak.person_id,
    ak.name,
    ak.name_pcode_nf,
    mh.title,
    mh.production_year
HAVING 
    COUNT(DISTINCT kc.id) > 3
ORDER BY 
    recent_movie_rank, 
    mh.production_year DESC, 
    ak.name;

### Explanation:

1. **Recursive CTE**: The `RecursiveMovieCTE` generates a hierarchy of movies linked together (via the `movie_link` table), allowing us to explore relationships up to 5 levels deep.

2. **Joins**:
    - Joins are established between the main tables to collect relevant data about movies and actors' characteristics. This includes a LEFT JOIN to allow for actors that might have no associated keywords.
  
3. **Conditional Filtering**: 
    - The query includes filtering on production years and name conditions as an example of obscure NULL handling.

4. **Subquery with EXISTS**: 
    - A subquery ensures that only movies classified as feature films are considered.

5. **Window Functions**: 
    - The query leverages the `ROW_NUMBER()` window function to rank movies for each actor based on the production year.

6. **HAVING Clause**: 
    - This clause ensures that only those who have acted in more than three distinct keywords are shown in the result.

7. **Sorting**: 
    - Finally, results are ordered first by `recent_movie_rank`, then by movie release year, and finally by actor name.

This SQL query combines various SQL constructs to create a complex and elaborate benchmark scenario to test performance under potentially competing criteria based on the `Join Order Benchmark` schema.
