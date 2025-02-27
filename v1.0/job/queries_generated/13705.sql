SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    p.info AS actor_info,
    c.kind AS cast_type
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.movie_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC;
