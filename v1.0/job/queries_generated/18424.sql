SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS role_type
FROM 
    cast_info AS ci
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    aka_title AS t ON ci.movie_id = t.movie_id
JOIN 
    role_type AS c ON ci.role_id = c.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
