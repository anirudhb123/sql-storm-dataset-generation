SELECT 
    t.title,
    a.name AS actor_name,
    c.role_id,
    ct.kind AS company_type,
    m.info AS movie_info
FROM 
    title t
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info m ON t.id = m.movie_id
ORDER BY 
    t.production_year DESC, 
    a.name;
