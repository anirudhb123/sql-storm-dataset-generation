WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title AS movie_title,
        1 AS level
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    WHERE 
        mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Production')
        
    UNION ALL
    
    SELECT 
        mh.movie_id,
        CONCAT(mh.movie_title, ' (linked to: ', m.title, ')') AS movie_title,
        level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON m.id = ml.linked_movie_id
)

SELECT 
    ka.name AS actor_name,
    t.production_year,
    m.movie_title,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    MAX(pi.info) FILTER (WHERE it.id = 1) AS birth_date,
    AVG(CASE WHEN ci.nr_order IS NULL THEN 0 ELSE ci.nr_order END) AS avg_order,
    ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY m.movie_title) AS row_num
FROM 
    aka_name ka
JOIN 
    cast_info ci ON ci.person_id = ka.person_id
JOIN 
    aka_title t ON t.id = ci.movie_id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword kc ON kc.id = mk.keyword_id
JOIN 
    person_info pi ON pi.person_id = ka.person_id
JOIN 
    info_type it ON it.id = pi.info_type_id
LEFT JOIN 
    movie_hierarchy m ON m.movie_id = t.id
WHERE 
    t.production_year IS NOT NULL
    AND mk.keyword IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM movie_link ml WHERE ml.movie_id = t.id AND ml.linked_movie_id IS NULL)
GROUP BY 
    ka.name, t.production_year, m.movie_title
HAVING 
    COUNT(DISTINCT kc.keyword) > 2
ORDER BY 
    t.production_year DESC, actor_name;
