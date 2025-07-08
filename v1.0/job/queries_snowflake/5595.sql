SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(ci.person_id) AS total_cast,
    c.name AS company_name,
    rt.role AS role_type
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
    t.production_year BETWEEN 2000 AND 2023
    AND c.country_code = 'USA'
GROUP BY 
    a.name, t.title, t.production_year, c.name, rt.role
HAVING 
    COUNT(ci.person_id) > 1
ORDER BY 
    t.production_year DESC, a.name ASC;
