SELECT 
    t.title, 
    a.name AS actor_name, 
    ci.note AS role_note 
FROM 
    title AS t 
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id 
JOIN 
    cast_info AS ci ON cc.subject_id = ci.id 
JOIN 
    aka_name AS a ON ci.person_id = a.person_id 
WHERE 
    t.production_year > 2000 
ORDER BY 
    t.production_year DESC;
