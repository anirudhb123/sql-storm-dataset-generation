SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_type,
    ci.note AS cast_note,
    mc.note AS company_note,
    mi.info AS movie_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND it.info = 'summary'
    AND ct.kind = 'Production'
ORDER BY 
    t.production_year DESC, a.name;
