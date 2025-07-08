SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    rt.role AS role,
    c.note AS cast_note,
    m.company_type_id AS company_type
FROM 
    aka_title t
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    role_type rt ON c.role_id = rt.id
JOIN 
    movie_companies m ON t.id = m.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
