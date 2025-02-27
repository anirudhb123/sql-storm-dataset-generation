WITH RECURSIVE movie_hierarchy AS (
    -- CTE to recursively gather movie dependencies
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM aka_title mt
    WHERE mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM movie_link ml
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE mh.depth < 3  -- Limit depth to avoid excessive recursion
)
SELECT 
    a.name AS actor_name,
    mt.title AS movie_title,
    mh.depth AS movie_depth,
    COALESCE(c.role_id, 0) AS role_id,
    CASE 
        WHEN c.role_id IS NULL THEN 'Unknown' 
        ELSE r.role 
    END AS role_description,
    COUNT(DISTINCT mw.keyword_id) AS keyword_count,
    AVG(CASE 
        WHEN mi.info IS NOT NULL THEN LENGTH(mi.info) 
        ELSE 0 
    END) AS avg_info_length
FROM aka_name a
JOIN cast_info c ON a.person_id = c.person_id
JOIN movie_hierarchy mh ON c.movie_id = mh.movie_id
JOIN title mt ON mh.movie_id = mt.id
LEFT JOIN movie_keyword mw ON mt.id = mw.movie_id
LEFT JOIN role_type r ON c.role_id = r.id
LEFT JOIN movie_info mi ON mt.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
WHERE mt.production_year BETWEEN 2000 AND 2023
    AND (c.note IS NULL OR c.note NOT LIKE '%guest%') -- Exclude guest roles
GROUP BY a.name, mt.title, mh.depth, c.role_id, r.role
ORDER BY movie_depth DESC, keyword_count DESC
LIMIT 50;
