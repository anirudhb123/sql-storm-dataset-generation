SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS role_description,
    c.kind AS company_type
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.person_role_id = r.id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_type c ON mc.company_type_id = c.id
ORDER BY 
    t.production_year DESC, 
    a.name;
