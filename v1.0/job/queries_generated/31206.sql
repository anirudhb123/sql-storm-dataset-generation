WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON m.id = ml.linked_movie_id
    WHERE 
        ml.link_type_id IN (SELECT id FROM link_type WHERE link = 'sequel')
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COALESCE(AVG(CASE WHEN r.role IS NOT NULL THEN 1 ELSE 0 END), 0) AS avg_role_assigned,
    COUNT(DISTINCT k.keyword) AS total_keywords,
    COUNT(DISTINCT mc.company_id) AS total_companies,
    COUNT(DISTINCT p.info) FILTER (WHERE p.info IS NOT NULL) AS total_person_info
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.id
LEFT JOIN 
    (SELECT 
         pi.person_id, 
         pi.info 
     FROM 
         person_info pi
     WHERE 
         pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')) p ON p.person_id = ci.person_id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year >= 2000
    AND t.production_year <= 2023
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT r.id) > 1  
ORDER BY 
    t.production_year DESC, avg_role_assigned DESC
LIMIT 10;
