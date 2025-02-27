SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS role_name,
    GROUP_CONCAT(DISTINCT c.kind ORDER BY c.kind) AS company_types
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
GROUP BY 
    a.name, t.title, t.production_year, r.role
ORDER BY 
    t.production_year DESC;
