WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level,
        title_id,
        0 AS hierarchy_distance
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        a.title,
        a.production_year,
        mh.level + 1,
        a.id AS title_id,
        LEAST(mh.hierarchy_distance + 1, (SELECT COUNT(*) FROM movie_link ml WHERE ml.movie_id = mh.movie_id)) AS hierarchy_distance
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.linked_movie_id
    JOIN 
        aka_title a ON ml.movie_id = a.id
)

SELECT 
    COALESCE(NULLIF(aka.name, ''), 'Unnamed') AS actor_name,
    COUNT(DISTINCT ch.movie_id) AS appearance_count,
    STRING_AGG(DISTINCT CONCAT(m.title, ' (', m.production_year, ')'), ', ') AS movies,
    MAX(mk.keyword) AS main_keyword,
    a.name_pcode_nf AS actor_name_geo,
    SUM(CASE WHEN ci.nr_order = 1 THEN 1 ELSE 0 END) AS leading_roles
FROM 
    aka_name aka
JOIN  
    cast_info ci ON aka.person_id = ci.person_id
JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
JOIN 
    movie_keyword mk ON mk.movie_id = ci.movie_id
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_title m ON m.id = ci.movie_id 
CROSS JOIN 
    (SELECT DISTINCT title FROM aka_title) AS all_titles 
WHERE 
    aka.name IS NOT NULL
    AND (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = ci.movie_id AND mi.info_type_id = 1) > 0
    AND m.production_year BETWEEN 1990 AND 2023
GROUP BY 
    actor_name,
    a.name_pcode_nf
HAVING 
    COUNT(DISTINCT ch.movie_id) > 5
    AND main_keyword IN (SELECT keyword FROM keyword WHERE LENGTH(keyword) > 3)
ORDER BY 
    appearance_count DESC, 
    actor_name,
    NULLIF(a.name_pcode_nf, '') ASC
LIMIT 10;
