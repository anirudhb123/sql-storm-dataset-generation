SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    p.info AS person_info,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    info_type it ON m.info_type_id = it.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
AND 
    c.kind = 'actor'
AND 
    it.info = 'awards'
ORDER BY 
    t.production_year DESC, 
    a.name;
