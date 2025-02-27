SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id,
    p.info AS actor_info,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_info m ON t.movie_id = m.movie_id
WHERE 
    a.name IS NOT NULL
    AND t.title IS NOT NULL
    AND p.info_type_id = 1  
    AND m.info_type_id = 1  
ORDER BY 
    a.name, t.title;