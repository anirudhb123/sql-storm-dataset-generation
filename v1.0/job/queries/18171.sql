SELECT 
    a.title,
    p.name AS person_name,
    c.note AS role_note
FROM 
    aka_title a
JOIN 
    cast_info c ON a.id = c.movie_id
JOIN 
    aka_name p ON c.person_id = p.person_id
WHERE 
    a.production_year = 2023
ORDER BY 
    a.title;
