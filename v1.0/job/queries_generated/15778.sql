SELECT 
    t.title, 
    p.name, 
    a.name AS aka_name
FROM 
    title t
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    person_info p ON c.person_id = p.person_id
WHERE 
    t.production_year = 2020
AND 
    p.info_type_id = 1;
