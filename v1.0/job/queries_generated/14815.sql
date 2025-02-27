SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    p.gender AS actor_gender,
    c.kind AS role_type,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year = 2020
ORDER BY 
    a.name, t.production_year;
