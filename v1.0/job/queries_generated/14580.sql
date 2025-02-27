SELECT 
    t.title,
    ak.name AS aka_name,
    c.name AS cast_name,
    p.info AS person_info
FROM 
    title t
JOIN 
    aka_title ak ON ak.movie_id = t.id
JOIN 
    cast_info ci ON ci.movie_id = t.id
JOIN 
    name c ON c.id = ci.person_id
JOIN 
    person_info p ON p.person_id = c.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
