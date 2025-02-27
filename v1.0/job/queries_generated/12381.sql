SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS actor_name,
    ct.kind AS cast_type,
    mc.note AS company_note,
    ki.keyword AS movie_keyword,
    ti.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    keyword ki ON t.id = ki.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    comp_cast_type ct ON ci.person_role_id = ct.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
