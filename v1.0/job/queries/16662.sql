SELECT 
    a.title,
    p.name,
    c.note
FROM 
    aka_title a
JOIN 
    complete_cast cc ON a.movie_id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name p ON c.person_id = p.person_id
WHERE 
    a.production_year = 2023;
