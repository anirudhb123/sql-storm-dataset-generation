SELECT 
    t.title,
    a.name AS actor_name,
    ci.role_id,
    cct.kind AS cast_type,
    mc.note AS company_note,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.movie_id
JOIN 
    title t ON at.id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    comp_cast_type cct ON ci.person_role_id = cct.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.title, a.name;
