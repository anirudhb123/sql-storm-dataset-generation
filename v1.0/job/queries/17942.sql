SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    c.note AS role_note
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
WHERE 
    m.production_year = 2020
ORDER BY 
    a.name;
