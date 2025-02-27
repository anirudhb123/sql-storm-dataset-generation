SELECT 
    t.title, 
    c.name AS cast_member, 
    kc.keyword AS movie_keyword, 
    ci.kind AS cast_type, 
    comp.name AS company_name, 
    ti.info AS movie_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info cinfo ON cc.subject_id = cinfo.id
JOIN 
    aka_name c ON c.id = cinfo.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kc ON mk.keyword_id = kc.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
JOIN 
    role_type ci ON cinfo.role_id = ci.id
WHERE 
    t.production_year >= 2000 
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%summary%')
ORDER BY 
    t.title, c.name;
