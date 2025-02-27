-- Performance Benchmarking Query for Join Order
SELECT 
    a.name AS actor_name, 
    m.title AS movie_title, 
    c.note AS cast_note, 
    p.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title m ON c.movie_id = m.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, a.name;
