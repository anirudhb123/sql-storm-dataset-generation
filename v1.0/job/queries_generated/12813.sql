SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS role_note,
    y.production_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    title y ON t.id = y.id
WHERE 
    y.production_year >= 2000
ORDER BY 
    y.production_year DESC, 
    a.name ASC;
