SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS character_type,
    mc.company_name AS production_company,
    ti.info AS additional_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN 
    title ti ON t.id = ti.id
WHERE 
    t.production_year >= 2000
    AND a.name LIKE '%Smith%'
    AND ci.nr_order <= 3
ORDER BY 
    t.production_year DESC, a.name;
