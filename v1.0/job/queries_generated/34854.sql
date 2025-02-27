WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(SUBSTRING(mt.title FROM '([0-9]+)')::integer, 0) AS release_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (1, 2)  -- Only consider movies and series

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        COALESCE(SUBSTRING(mt.title FROM '([0-9]+)')::integer, 0) AS release_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    mk.keyword,
    COUNT(DISTINCT m.id) AS movies_count,
    AVG(EXTRACT(YEAR FROM (CURRENT_DATE - TO_DATE(m.production_year::text, 'YYYY'))) / 365.25) AS avg_age,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    COUNT(DISTINCT CASE WHEN c.role_id IS NOT NULL THEN c.id ELSE NULL END) AS cast_member_count
FROM 
    movie_keyword mk
JOIN 
    aka_title m ON mk.movie_id = m.id
LEFT JOIN 
    cast_info c ON c.movie_id = m.id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_hierarchy mh ON m.id = mh.movie_id
WHERE 
    mk.keyword IN ('action', 'drama', 'comedy') 
    AND (m.production_year BETWEEN 1990 AND 2023 OR m.production_year IS NULL)
GROUP BY 
    mk.keyword
HAVING 
    COUNT(DISTINCT m.id) > 10
ORDER BY 
    movies_count DESC, avg_age ASC;

This query generates a comprehensive performance benchmark involving various SQL constructs:

1. **Recursive CTE (Common Table Expression)**: It builds a movie hierarchy to extract linked movies and their details recursively.
   
2. **Joins**: The query incorporates LEFT JOINs to include movies without associated cast members.

3. **Aggregations**: It counts the number of distinct movies, calculates the average age of movies, and aggregates actor names into a comma-separated list.

4. **Window Functions**: Although not explicitly used in this query, window functions can be applied in a variation for additional ranking or running totals if required.

5. **Check on NULL values**: It effectively includes conditions to handle potential NULLs in `production_year`.

6. **Set Operations**: Using `IN` with multiple keywords demonstrates set filtering.

7. **HAVING clause**: The results are filtered to include only those keywords with more than 10 movies.

This query demonstrates a robust SQL skill set suitable for performance benchmarking within a movie-related schema.
