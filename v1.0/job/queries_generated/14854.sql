SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    c.kind AS role_type,
    m.production_year,
    ci.note AS cast_note
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.id
JOIN 
    role_type c ON ci.role_id = c.id
WHERE 
    m.production_year > 2000
ORDER BY 
    m.production_year DESC, a.name;
