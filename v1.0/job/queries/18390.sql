SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS role_note,
    t.production_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
ORDER BY 
    t.production_year DESC
LIMIT 10;
