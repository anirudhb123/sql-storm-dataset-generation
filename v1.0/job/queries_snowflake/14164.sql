SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    r.role AS role,
    m.production_year,
    c.name AS company_name
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title m ON ci.movie_id = m.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON m.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, a.name;
