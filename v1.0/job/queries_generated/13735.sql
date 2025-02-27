SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    c.role_id,
    ci.note AS character_note,
    m.info AS movie_info
FROM 
    title t
JOIN 
    aka_title ak_t ON t.id = ak_t.movie_id
JOIN 
    aka_name ak ON ak_t.id = ak.id
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
