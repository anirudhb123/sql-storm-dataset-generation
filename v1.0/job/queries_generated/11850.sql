SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    role.role AS actor_role,
    c.note AS cast_note,
    comp.name AS company_name,
    info.info AS movie_info
FROM 
    title t
JOIN 
    movie_companies m ON t.id = m.movie_id
JOIN 
    company_name comp ON m.company_id = comp.id
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    role_type role ON c.role_id = role.id
JOIN 
    movie_info info ON t.id = info.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, t.title;
