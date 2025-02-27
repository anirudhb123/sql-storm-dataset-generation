SELECT 
    t.title,
    p.name AS person_name,
    c.kind AS cast_type
FROM 
    title AS t
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    cast_info AS ci ON cc.subject_id = ci.id
JOIN 
    aka_name AS p ON ci.person_id = p.person_id
JOIN 
    role_type AS c ON ci.role_id = c.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
