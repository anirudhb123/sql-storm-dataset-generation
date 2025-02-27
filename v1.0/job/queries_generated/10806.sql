SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.role_id AS actor_role, 
    m.production_year AS release_year, 
    c.nr_order AS cast_order
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    title m ON t.id = m.id
WHERE 
    m.production_year BETWEEN 2000 AND 2020
ORDER BY 
    m.production_year DESC, 
    a.name;
