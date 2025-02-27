SELECT 
    a.person_id,
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS role_type,
    c.kind AS company_type,
    COUNT(*) AS total_movies
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
    company_name c ON mc.company_id = c.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND c.country_code = 'USA'
GROUP BY 
    a.person_id, a.name, t.title, t.production_year, r.role, c.kind
HAVING 
    COUNT(*) > 5
ORDER BY 
    total_movies DESC;
