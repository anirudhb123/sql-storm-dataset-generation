SELECT 
    t.title,
    a.name AS actor_name,
    c.kind AS character_name,
    m.name AS company_name,
    mt.kind AS company_type
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
