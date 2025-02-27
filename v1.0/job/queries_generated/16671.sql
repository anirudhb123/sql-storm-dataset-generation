SELECT 
    p.id AS person_id,
    p.name AS person_name,
    m.id AS movie_id,
    m.title AS movie_title,
    c.note AS cast_note
FROM 
    cast_info c
JOIN 
    aka_name p ON c.person_id = p.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC;
