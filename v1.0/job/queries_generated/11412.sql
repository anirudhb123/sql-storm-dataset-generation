SELECT 
    at.title AS movie_title,
    ak.name AS actor_name,
    pc.kind AS person_role,
    ctt.kind AS company_type,
    ki.keyword AS keyword,
    ti.info AS movie_info
FROM 
    aka_title at
JOIN 
    cast_info ci ON at.id = ci.movie_id
JOIN 
    aka_name ak ON ak.person_id = ci.person_id
JOIN 
    comp_cast_type cct ON cct.id = ci.person_role_id
JOIN 
    movie_companies mc ON mc.movie_id = at.id
JOIN 
    company_type ct ON ct.id = mc.company_type_id
JOIN 
    company_name cn ON cn.id = mc.company_id
JOIN 
    movie_keyword mk ON mk.movie_id = at.id
JOIN 
    keyword ki ON ki.id = mk.keyword_id
JOIN 
    movie_info mi ON mi.movie_id = at.id
JOIN 
    info_type ti ON ti.id = mi.info_type_id
WHERE 
    at.production_year >= 2000
ORDER BY 
    at.production_year DESC, at.title;
