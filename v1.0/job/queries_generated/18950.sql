SELECT 
    t.title,
    a.name AS actor_name,
    w.kind AS role
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type w ON ci.role_id = w.id
WHERE 
    t.production_year = 2021
ORDER BY 
    t.title;
