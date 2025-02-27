WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    UNION ALL
    SELECT 
        m.id,
        COALESCE(NULLIF(m.title, ''), 'Untitled') AS movie_title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.linked_movie_id
)
SELECT 
    a.name AS actor_name,
    t.movie_title,
    COUNT(DISTINCT mf.info) AS info_count,
    AVG(CASE 
        WHEN tk.keyword IS NOT NULL THEN 1 
        ELSE 0 
    END) AS avg_keywords,
    STRING_AGG(COALESCE(ti.info, 'N/A'), ', ') AS additional_info,
    SUM(CASE 
        WHEN c.nr_order IS NULL THEN 0 
        ELSE c.nr_order 
    END) AS total_order
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_hierarchy t ON c.movie_id = t.movie_id
LEFT JOIN 
    movie_info mf ON mf.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.movie_id
LEFT JOIN 
    keyword tk ON tk.id = mk.keyword_id
LEFT JOIN 
    movie_info ti ON ti.movie_id = t.movie_id AND ti.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%plot%')
WHERE 
    t.production_year > 2000
GROUP BY 
    a.name, t.movie_title, t.production_year
ORDER BY 
    total_order DESC, avg_keywords ASC
LIMIT 50 OFFSET 0;
