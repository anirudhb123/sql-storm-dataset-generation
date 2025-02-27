SELECT 
    t.title, 
    a.name, 
    c.note 
FROM 
    title t 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    cast_info c ON cc.subject_id = c.id 
JOIN 
    aka_name a ON c.person_id = a.person_id 
WHERE 
    t.production_year = 2023 
ORDER BY 
    t.title;
