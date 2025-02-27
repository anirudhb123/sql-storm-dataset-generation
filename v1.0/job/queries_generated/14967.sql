SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS role_type,
    c.note AS cast_note,
    m.production_year,
    p.info AS person_info
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, 
    a.name;
