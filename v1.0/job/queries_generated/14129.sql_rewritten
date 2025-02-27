SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    t.title AS movie_title,
    t.production_year,
    c.name AS company_name,
    rt.role AS role_name
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
    role_type rt ON ci.role_id = rt.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;