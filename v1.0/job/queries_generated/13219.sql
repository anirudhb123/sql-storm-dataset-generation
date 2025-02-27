SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS actor_role,
    c.note AS cast_note,
    pc.info AS person_info
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.person_id AND cc.movie_id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    person_info pi ON a.person_id = pi.person_id
JOIN 
    info_type it ON pi.info_type_id = it.id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
