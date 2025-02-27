SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    c.note AS character_name,
    p.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title m ON ci.movie_id = m.id
JOIN 
    char_name c ON ci.person_role_id = c.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    m.production_year = 2023;
