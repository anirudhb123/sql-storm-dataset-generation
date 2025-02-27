SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS cast_type,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT m.company_id) AS production_companies,
    AVG(CASE WHEN mi.info IS NOT NULL THEN 1 ELSE 0 END) * 100 AS info_complete_percentage
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies m ON m.movie_id = t.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = t.id
WHERE 
    t.production_year >= 2000
GROUP BY 
    a.id, t.id, c.kind
ORDER BY 
    t.production_year DESC, actor_name;
