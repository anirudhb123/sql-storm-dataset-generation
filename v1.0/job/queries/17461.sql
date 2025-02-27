SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    ti.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_info ti ON t.id = ti.movie_id
WHERE 
    ti.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
ORDER BY 
    a.name, t.title;
