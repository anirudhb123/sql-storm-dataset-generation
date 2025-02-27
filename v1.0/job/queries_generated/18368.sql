SELECT 
    t.title,
    a.name AS actor_name,
    p.gender,
    m.info AS movie_info
FROM 
    title t
JOIN 
    aka_title a_t ON t.id = a_t.movie_id
JOIN 
    cast_info c ON a_t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    m.info_type_id = 1 AND p.info_type_id = 1
ORDER BY 
    t.title;
