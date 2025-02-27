SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.note AS cast_note,
    pc.kind AS person_role,
    mc.company_type_id AS company_type_id,
    ki.keyword AS movie_keyword,
    mi.info AS movie_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    role_type pc ON c.role_id = pc.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
