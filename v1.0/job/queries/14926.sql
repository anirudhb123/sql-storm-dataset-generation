SELECT 
    a.name AS actor_name, 
    at.title AS movie_title, 
    c.note AS role_note, 
    t.production_year AS movie_year 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    aka_title at ON c.movie_id = at.movie_id 
JOIN 
    title t ON at.movie_id = t.id 
WHERE 
    t.production_year >= 2000 
ORDER BY 
    movie_year DESC, 
    actor_name ASC;
