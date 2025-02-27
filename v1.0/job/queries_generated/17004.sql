SELECT 
    t.title,
    a.name AS actor_name,
    p.info AS actor_info
FROM 
    title t
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    complete_cast c ON t.id = c.movie_id
JOIN 
    cast_info ci ON c.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
