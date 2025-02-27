SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id AS role_id,
    m.production_year AS production_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    title m ON m.id = t.movie_id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC;
