WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        lt.title,
        lt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title lt ON ml.linked_movie_id = lt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    m.title AS original_movie_title,
    m.production_year AS original_movie_year,
    c.name AS company_name,
    c.country_code AS company_country,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT ca.person_id) AS cast_count,
    MAX(CASE WHEN ca.nr_order = 1 THEN a.name END) AS lead_actor,
    COUNT(DISTINCT DISTINCT l.linked_movie_id) AS linked_movies_count,
    SUM(CASE WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') THEN CAST(pi.info AS FLOAT) END) AS average_rating
FROM 
    movie_hierarchy m
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ca ON cc.subject_id = ca.person_id
LEFT JOIN 
    person_info pi ON ca.person_id = pi.person_id
LEFT JOIN 
    movie_link l ON m.movie_id = l.movie_id
GROUP BY 
    m.movie_id, c.name, c.country_code
HAVING 
    COUNT(DISTINCT pi.info_type_id) > 0
ORDER BY 
    average_rating DESC, m.production_year DESC
LIMIT 50;
