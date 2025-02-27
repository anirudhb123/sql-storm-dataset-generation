SELECT 
    t.title, 
    ak.name AS aka_name, 
    c.role_id, 
    p.info AS person_info, 
    m.info AS movie_info
FROM 
    title t
JOIN 
    aka_title ak ON t.id = ak.movie_id
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    name n ON c.person_id = n.id
JOIN 
    person_info p ON n.id = p.person_id
JOIN 
    movie_info m ON m.movie_id = t.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.title;
