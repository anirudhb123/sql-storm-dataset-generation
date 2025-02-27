SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    t.id AS title_id,
    t.title AS movie_title,
    c.person_id,
    c.movie_id,
    p.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    person_info p ON c.person_id = p.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
ORDER BY 
    t.production_year DESC, a.name;
