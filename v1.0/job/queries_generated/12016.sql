SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    ct.kind AS company_type,
    ki.keyword AS movie_keyword,
    ti.info AS movie_info,
    r.role AS role_type
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
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
    info_type ti ON mi.info_type_id = ti.id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
