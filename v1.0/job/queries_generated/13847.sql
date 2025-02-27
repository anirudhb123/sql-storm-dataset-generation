SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    cr.role AS role_type,
    COUNT(*) AS num_appearances
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type cr ON ci.role_id = cr.id
WHERE 
    t.production_year >= 2000
GROUP BY 
    a.name, t.title, t.production_year, cr.role
ORDER BY 
    num_appearances DESC
LIMIT 10;
