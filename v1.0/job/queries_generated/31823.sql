WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS depth,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1,
        CONCAT(mh.path, ' -> ', at.title)
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        at.production_year IS NOT NULL
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    mh.depth,
    mh.path,
    COUNT(DISTINCT ca.person_id) AS actor_count,
    AVG(COALESCE(ci.nr_order, 0)) AS avg_order,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    mh.production_year > 2000
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year, mh.depth, mh.path
HAVING 
    COUNT(DISTINCT ca.person_id) > 3
ORDER BY 
    mh.production_year DESC, mh.depth ASC;

### Explanation:
- **CTE (Common Table Expression):** 
    - `movie_hierarchy`: This recursive CTE builds a hierarchy of movies based on links between them. It starts with movies that have a known production year and then recursively finds linked movies.
  
- **Main Query:**
    - Joins the CTE with the `complete_cast`, `cast_info`, and `aka_name` tables to gather data about the movies and their actors.
    - It applies a `WHERE` condition to only include movies produced after the year 2000.
    - The `HAVING` clause enforces that only movies with more than three distinct actors are included in the results.
  
- **Aggregations:**
    - It counts distinct actors and calculates the average order from `cast_info`.
    - It combines actor names into a single string using `STRING_AGG`.

- **Ordering:**
    - Results are ordered by production year in descending order and depth in ascending order for a focused view of more recent films first, while also considering the hierarchy depth.

This query leverages multiple advanced SQL features, including CTEs, joins, aggregates, string functions, and conditional logic for a comprehensive performance benchmark scenario.
