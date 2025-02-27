SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.info AS person_info,
    r.role AS role_type,
    m.note AS movie_note
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    title AS t ON c.movie_id = t.id
JOIN 
    person_info AS p ON a.person_id = p.person_id
JOIN 
    role_type AS r ON c.role_id = r.id
JOIN 
    movie_info AS m ON t.id = m.movie_id
WHERE 
    t.production_year BETWEEN 1990 AND 2023
ORDER BY 
    t.production_year DESC;
