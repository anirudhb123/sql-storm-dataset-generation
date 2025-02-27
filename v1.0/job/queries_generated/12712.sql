SELECT 
    at.title AS movie_title, 
    ak.name AS actor_name, 
    r.role AS role_type, 
    c.note AS cast_note, 
    m.info AS movie_info
FROM 
    aka_title at
JOIN 
    cast_info c ON at.id = c.movie_id
JOIN 
    aka_name ak ON c.person_id = ak.person_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_info m ON at.id = m.movie_id
WHERE 
    at.production_year >= 2000
ORDER BY 
    at.production_year DESC, 
    ak.name;
