SELECT 
    ak.name AS aka_name,
    ti.title AS movie_title,
    cc.nr_order AS cast_order,
    cn.name AS company_name,
    ki.keyword AS movie_keyword,
    ci.info AS movie_info,
    rt.role AS person_role
FROM 
    aka_name ak
JOIN 
    cast_info cc ON ak.person_id = cc.person_id
JOIN 
    title ti ON cc.movie_id = ti.id
JOIN 
    movie_info mi ON ti.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    movie_keyword mk ON ti.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
JOIN 
    movie_companies mc ON ti.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    role_type rt ON cc.role_id = rt.id
WHERE 
    ak.name ILIKE '%Smith%'
    AND ti.production_year BETWEEN 2000 AND 2023
    AND it.info ILIKE '%Awards%'
ORDER BY 
    ti.production_year DESC,
    cc.nr_order ASC;
