SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS role_note,
    t.production_year,
    p.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
ORDER BY 
    t.production_year DESC;
