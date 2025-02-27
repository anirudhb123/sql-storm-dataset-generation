SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.person_role_id,
    ci.note AS cast_note,
    ti.info AS movie_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    title ti ON t.id = ti.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
