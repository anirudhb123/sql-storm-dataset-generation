
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.kind_id,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.kind_id,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    COALESCE(cn.name, 'Unknown') AS company_name,
    COALESCE(ki.keyword, 'None') AS keyword,
    COUNT(DISTINCT ti.id) AS total_movies,
    AVG(CASE WHEN ti.production_year IS NOT NULL THEN ti.production_year ELSE NULL END) AS avg_production_year,
    LISTAGG(DISTINCT ti.title, ', ') WITHIN GROUP (ORDER BY ti.title) AS movie_titles,
    COUNT(DISTINCT ci.person_id) FILTER (WHERE ci.note IS NOT NULL) AS actors_count,
    ROW_NUMBER() OVER (PARTITION BY cn.name ORDER BY COUNT(DISTINCT ti.id) DESC) AS rn
FROM 
    company_name cn
LEFT JOIN 
    movie_companies mc ON cn.id = mc.company_id
LEFT JOIN 
    aka_title ti ON mc.movie_id = ti.id
LEFT JOIN 
    movie_keyword mk ON ti.id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    complete_cast cc ON ti.id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
WHERE 
    ti.production_year IS NOT NULL
    AND (ti.production_year > 2000 OR ti.title ILIKE '%Epic%')
GROUP BY 
    cn.name, ki.keyword
HAVING 
    COUNT(DISTINCT ti.id) > 1
ORDER BY 
    total_movies DESC, company_name
LIMIT 50;
