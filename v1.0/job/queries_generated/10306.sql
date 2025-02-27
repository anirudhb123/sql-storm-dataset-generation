SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS role_type,
    c.name AS company_name,
    mi.info AS movie_info
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type ct ON ci.role_id = ct.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = 1
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
