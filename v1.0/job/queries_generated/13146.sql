SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    ci.kind AS comp_cast_type,
    co.name AS company_name,
    ki.keyword AS movie_keyword,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    comp_cast_type ci ON c.person_role_id = ci.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
