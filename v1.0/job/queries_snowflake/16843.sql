SELECT 
    a.title, 
    p.name AS actor_name, 
    c.role_id 
FROM 
    aka_title a 
JOIN 
    complete_cast cc ON a.id = cc.movie_id 
JOIN 
    cast_info c ON cc.subject_id = c.person_id 
JOIN 
    aka_name p ON c.person_id = p.person_id 
WHERE 
    a.production_year > 2000 
ORDER BY 
    a.production_year DESC;
