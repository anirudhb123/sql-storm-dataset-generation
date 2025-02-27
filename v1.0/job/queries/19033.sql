SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    c.note AS role_note,
    t.production_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
JOIN 
    title t ON m.movie_id = t.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
