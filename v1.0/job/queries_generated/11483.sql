SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.note AS role_note,
    p.info AS person_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    aka_title AS t ON c.movie_id = t.movie_id
JOIN 
    person_info AS p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
