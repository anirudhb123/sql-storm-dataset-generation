SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id AS character_role,
    m.production_year AS movie_year
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    title m ON t.movie_id = m.id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC;
