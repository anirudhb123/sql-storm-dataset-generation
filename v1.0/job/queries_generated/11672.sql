SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    c.kind AS role_type,
    y.production_year AS production_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.movie_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    title y ON m.id = y.id
WHERE 
    y.production_year >= 2000
ORDER BY 
    y.production_year DESC, 
    a.name;
