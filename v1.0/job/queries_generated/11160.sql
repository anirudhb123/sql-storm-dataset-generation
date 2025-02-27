SELECT 
    t.title, 
    a.name AS actor_name, 
    c.kind AS character_role, 
    m.info AS movie_info
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info c ON at.movie_id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.title ASC;
