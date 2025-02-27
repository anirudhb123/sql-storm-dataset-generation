WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        mt.episode_of_id,
        CAST(mt.title AS VARCHAR(255)) AS full_title
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        mt.episode_of_id,
        CAST(mh.full_title || ' -> ' || mt.title AS VARCHAR(255)) AS full_title
    FROM 
        aka_title mt
    INNER JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
)

SELECT 
    a.name,
    m.title,
    m.production_year,
    COUNT(DISTINCT c.id) AS cast_count,
    STRING_AGG(DISTINCT c.note, ', ') AS cast_notes,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS row_num,
    COALESCE(mh.full_title, 'Standalone Movie') AS movie_hierarchy_title,
    AVG(CASE 
        WHEN mi.info_type_id = 1 THEN LENGTH(mi.info) 
        ELSE NULL 
    END) AS avg_info_length
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title m ON c.movie_id = m.id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id AND mi.info_type_id IN (1, 2) 
LEFT JOIN 
    movie_hierarchy mh ON m.id = mh.movie_id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
    AND a.name IS NOT NULL
GROUP BY 
    a.name, m.title, m.production_year, mh.full_title
HAVING 
    COUNT(DISTINCT c.id) > 1
ORDER BY 
    m.production_year DESC, a.name;