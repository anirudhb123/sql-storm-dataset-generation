WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth,
        CAST(m.title AS VARCHAR(255)) AS path
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL 

    UNION ALL

    SELECT
        mc.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        mh.depth + 1,
        CAST(mh.path || ' -> ' || a.title AS VARCHAR(255)) AS path
    FROM 
        movie_link mc
    JOIN
        aka_title a ON mc.linked_movie_id = a.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = mc.movie_id
)
SELECT 
    mh.path,
    mh.depth,
    count(DISTINCT kc.keyword) FILTER (WHERE kc.keyword IS NOT NULL) AS keyword_count,
    count(DISTINCT ci.person_id) FILTER (WHERE ci.note IS NOT NULL) AS cast_count,
    COUNT(DISTINCT CASE WHEN a.name LIKE '%Star%' THEN a.name END) AS star_names
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    complete_cast cc ON cc.movie_id = mh.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
WHERE 
    mh.depth <= 3
GROUP BY 
    mh.path, mh.depth
HAVING 
    count(DISTINCT mk.keyword_id) > 5
ORDER BY 
    mh.depth, keyword_count DESC;

This elaborate SQL query demonstrates several advanced concepts:

1. **Recursive CTE**: It retrieves a hierarchical listing of movies and their links up to three levels deep.
   
2. **Left Joins**: It collects additional data about keywords and cast info related to the movies.

3. **Aggregations with Filters**: It counts distinct keywords and cast members, applying filters to ensure only relevant counts are included.

4. **Complicated HAVING Clause**: It only includes movie paths that have more than five distinct keywords, filtering out less significant results.

5. **String Manipulation**: It builds a full path string representing the movie hierarchy using `CAST` for concatenation.

6. **Conditional Count**: It counts the occurrences of names containing "Star", providing insight into well-known names among the casts.

7. **NULL Logic**: Properly handles potential NULL values in the joins and calculations, ensuring accurate counting. 

This query strikes a balance between complexity and the potential for insightful data retrieval, perfect for performance benchmarking.
