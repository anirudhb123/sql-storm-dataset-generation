SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS role_type,
    c.kind AS company_type,
    i.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_info i ON t.id = i.movie_id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
