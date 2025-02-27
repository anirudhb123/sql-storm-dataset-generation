SELECT 
    t.title AS movie_title,
    p.name AS person_name,
    r.role AS role_name,
    c.note AS cast_note,
    ci.kind AS company_type,
    m.info AS movie_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    aka_name p ON c.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year >= 2000
    AND ct.kind LIKE 'Production%'
ORDER BY 
    t.production_year DESC, t.title, p.name;
