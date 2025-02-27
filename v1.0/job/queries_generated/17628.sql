SELECT 
    t.title, 
    a.name AS actor_name, 
    c.kind AS cast_type 
FROM 
    title t 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id 
JOIN 
    aka_name a ON ci.person_id = a.person_id 
JOIN 
    comp_cast_type c ON ci.role_id = c.id 
WHERE 
    t.production_year = 2020 
ORDER BY 
    t.title;
