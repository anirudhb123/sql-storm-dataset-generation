-- Performance Benchmarking Query

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.role_id,
    COUNT(*) AS num_of_roles
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    title ti ON t.id = ti.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, t.production_year, c.role_id
ORDER BY 
    num_of_roles DESC
LIMIT 100;
