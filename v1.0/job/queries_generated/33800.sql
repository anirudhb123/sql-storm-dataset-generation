WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.kind_id = 1 -- Assuming '1' corresponds to a specific type like 'feature film'
  
    UNION ALL
  
    SELECT 
        ml.linked_movie_id,
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
    mv.title AS main_movie,
    COUNT(DISTINCT ca.person_id) AS total_cast,
    AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS avg_has_note,
    STRING_AGG(DISTINCT cn.name, ', ') AS cast_names,
    mh.depth AS movie_depth
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ca ON cc.subject_id = ca.person_id
LEFT JOIN 
    aka_name cn ON ca.person_id = cn.person_id
INNER JOIN 
    aka_title mv ON mh.movie_id = mv.id
WHERE 
    mv.production_year >= 2000
    AND mv.title IS NOT NULL
GROUP BY 
    mv.title, mh.depth
ORDER BY 
    movie_depth, total_cast DESC
LIMIT 50;

This query creates a recursive common table expression (CTE) to explore a hierarchy of movies linked through `movie_link`, counting the cast members for each movie and determining if they have notes. Additionally, it aggregates cast names and filters on movies produced after 2000, demonstrating the complex use of joins, aggregation, and recursive relationships in SQL.
