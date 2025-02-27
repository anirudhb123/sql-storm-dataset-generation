
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS actor_role,
    c.name AS company_name,
    COUNT(DISTINCT t.id) AS total_movies
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
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year BETWEEN 1990 AND 2023
    AND r.role IN ('Actor', 'Director')
GROUP BY 
    a.name, t.title, t.production_year, r.role, c.name
HAVING 
    COUNT(DISTINCT t.id) > 5
ORDER BY 
    total_movies DESC, t.production_year DESC;
