SELECT 
    t.title,
    p.name,
    c.nr_order,
    r.role
FROM 
    title AS t
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    cast_info AS c ON cc.subject_id = c.id
JOIN 
    aka_name AS p ON c.person_id = p.person_id
JOIN 
    role_type AS r ON c.role_id = r.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    c.nr_order;
