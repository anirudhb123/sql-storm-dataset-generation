
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        CAST(NULL AS VARCHAR) AS parent_title,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.title AS parent_title,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
)
SELECT 
    a.person_id,
    a.name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    AVG(CASE 
            WHEN c.nr_order = 1 THEN 1 
            ELSE 0 
        END) AS lead_actors,
    LISTAGG(DISTINCT CONCAT(mh.title, ' (', mh.production_year, ')'), ', ') AS movies,
    COALESCE(SUM(CASE 
            WHEN mi.info_type_id = 1 THEN LENGTH(mi.info) 
            ELSE 0 
        END), 0) AS total_info_length
FROM 
    aka_name a
LEFT JOIN 
    cast_info c ON a.person_id = c.person_id
LEFT JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    movie_info mi ON c.movie_id = mi.movie_id AND mi.info_type_id IN (1, 2)
WHERE 
    a.name IS NOT NULL
    AND a.name NOT LIKE '%test%'
    AND a.person_id IS NOT NULL
GROUP BY 
    a.person_id, 
    a.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 0
    AND SUM(CASE 
            WHEN c.nr_order = 1 THEN 1 
            ELSE 0 
        END) > 2
ORDER BY 
    movie_count DESC, 
    a.name ASC;
