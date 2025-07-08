SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS role_order,
    r.role AS role_name,
    y.production_year AS year
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    title AS t ON c.movie_id = t.id
JOIN 
    role_type AS r ON c.role_id = r.id
JOIN 
    aka_title AS y ON t.id = y.movie_id
WHERE 
    c.nr_order IS NOT NULL
ORDER BY 
    year DESC, 
    actor_name;
