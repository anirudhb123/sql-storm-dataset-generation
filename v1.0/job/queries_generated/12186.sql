SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS role,
    c.note AS cast_note,
    m.production_year
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, t.title;
