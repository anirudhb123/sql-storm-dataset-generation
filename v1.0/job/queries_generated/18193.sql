SELECT 
    t.title, 
    a.name AS actor_name, 
    c.kind AS role_type
FROM 
    aka_title AS t
JOIN 
    cast_info AS c ON t.id = c.movie_id
JOIN 
    aka_name AS a ON c.person_id = a.person_id
WHERE 
    t.production_year = 2020
ORDER BY 
    t.title, a.name;
