SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    p.info_type_id = 1 -- Assuming 1 is a specific info type
    AND t.production_year >= 2000; -- Filtering for movies produced after 2000
