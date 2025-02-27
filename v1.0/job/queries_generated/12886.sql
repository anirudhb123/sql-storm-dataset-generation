SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_type,
    y.production_year
FROM 
    title AS t
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    role_type AS c ON ci.role_id = c.id
JOIN 
    aka_title AS y ON t.id = y.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
