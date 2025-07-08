SELECT 
    ak.name AS aka_name, 
    t.title AS movie_title, 
    c.note AS cast_note
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
