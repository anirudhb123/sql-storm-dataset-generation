SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    ct.kind AS cast_type,
    c.name AS company_name,
    kt.keyword AS movie_keyword,
    ti.info AS movie_info,
    l.link AS movie_link
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
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
JOIN 
    comp_cast_type ct ON ci.person_role_id = ct.id
ORDER BY 
    t.production_year DESC, a.name;
