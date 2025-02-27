SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.info AS person_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    title AS t ON c.movie_id = t.id
JOIN 
    person_info AS p ON a.person_id = p.person_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
