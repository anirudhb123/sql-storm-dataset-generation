SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS character_type,
    mc.company_name AS production_company,
    ti.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    t.production_year > 2000 
    AND (it.info LIKE '%box office%' OR it.info LIKE '%awards%')
ORDER BY 
    t.production_year DESC, a.name;
