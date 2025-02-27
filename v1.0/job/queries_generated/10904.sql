SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS character_name,
    c.kind AS company_type,
    m.info AS movie_info
FROM 
    cast_info ci
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    movie_companies mc ON mc.movie_id = ci.movie_id
JOIN 
    company_name cn ON cn.id = mc.company_id
JOIN 
    company_type c ON c.id = mc.company_type_id
JOIN 
    title t ON t.id = ci.movie_id
JOIN 
    role_type r ON r.id = ci.role_id
JOIN 
    movie_info m ON m.movie_id = ci.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
