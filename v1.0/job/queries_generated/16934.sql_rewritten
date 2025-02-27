SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    ti.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_info ti ON t.id = ti.movie_id
WHERE 
    ti.info_type_id = 1  
ORDER BY 
    t.production_year DESC;