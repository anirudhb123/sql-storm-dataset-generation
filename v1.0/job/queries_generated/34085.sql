WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ml.linked_movie_id,
        1 AS level
    FROM title m
    LEFT JOIN movie_link ml ON m.id = ml.movie_id
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        ml.linked_movie_id,
        mh.level + 1
    FROM movie_hierarchy mh
    JOIN movie_link ml ON mh.linked_movie_id = ml.movie_id
)
SELECT 
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT c.person_id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS all_names,
    AVG(CASE WHEN p.info IS NOT NULL THEN LENGTH(p.info) ELSE 0 END) AS avg_info_length,
    SUM(CASE 
            WHEN c.role_id IS NOT NULL 
            THEN 1 
            ELSE 0 
        END) AS total_roles,
    MAX(mh.level) AS max_depth
FROM 
    movie_hierarchy mh
JOIN 
    aka_title m ON mh.movie_id = m.movie_id
JOIN 
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN 
    person_info p ON c.person_id = p.person_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
GROUP BY 
    m.title, m.production_year
HAVING 
    MAX(mh.level) > 1 
ORDER BY 
    avg_info_length DESC, cast_count DESC;
