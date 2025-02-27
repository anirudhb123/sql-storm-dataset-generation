
SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS role_note
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    cast_info c ON ci.movie_id = c.movie_id AND ci.person_id = c.person_id
WHERE 
    t.production_year = 2020
ORDER BY 
    a.name;
