WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = 1  -- Let's say 1 corresponds to feature films.
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id, 
        mt.title, 
        mt.production_year, 
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT cc.subject_id) AS total_cast,
    AVG(CASE WHEN pi.info_type_id = 1 THEN LENGTH(pi.info) ELSE NULL END) AS avg_info_length,  -- Assuming info_type_id 1 relates to a specific info type
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords_list
FROM 
    movie_hierarchy m
JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    m.production_year BETWEEN 2000 AND 2023 
    AND a.name IS NOT NULL
GROUP BY 
    a.name, m.title, m.production_year
HAVING 
    COUNT(DISTINCT ci.role_id) > 1
ORDER BY 
    m.production_year DESC, total_cast DESC;


This query combines recursive CTEs to build a movie hierarchy from linked movies, while joining multiple tables to extract and aggregate data about actors, their roles, and related keywords. The use of window functions, conditional aggregation, and string aggregation adds complexity and performance considerations to the benchmarking exercise.
