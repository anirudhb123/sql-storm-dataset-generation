SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    r.role AS role_name, 
    c.note AS cast_note, 
    p.info AS person_info, 
    ci.kind AS company_type
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ci ON mc.company_type_id = ci.id
WHERE 
    t.production_year >= 2000
AND 
    ci.kind = 'Distributor'
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
