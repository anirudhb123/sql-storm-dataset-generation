SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    p.info AS person_info, 
    c.kind AS cast_type, 
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    person_info p ON p.person_id = a.person_id
JOIN 
    comp_cast_type c ON ci.role_id = c.id
JOIN 
    movie_info m ON m.movie_id = t.id
ORDER BY 
    a.name, t.title;
