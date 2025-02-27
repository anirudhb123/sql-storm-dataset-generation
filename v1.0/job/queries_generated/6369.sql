SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.role_id AS role_id, 
    p.info AS person_info, 
    k.keyword AS movie_keyword,
    COUNT(DISTINCT mc.company_id) AS production_company_count
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
LEFT JOIN 
    person_info p ON a.person_id = p.person_id 
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
GROUP BY 
    a.name, t.title, c.role_id, p.info, k.keyword 
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    production_company_count DESC, t.title;
