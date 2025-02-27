SELECT 
    na.name AS actor_name,
    ti.title AS movie_title,
    ti.production_year,
    cct.kind AS cast_type,
    mn.name AS company_name,
    mi.info AS movie_info
FROM 
    cast_info ci
JOIN 
    aka_name na ON ci.person_id = na.person_id
JOIN 
    aka_title ti ON ci.movie_id = ti.movie_id
JOIN 
    movie_companies mc ON ti.id = mc.movie_id
JOIN 
    company_name mn ON mc.company_id = mn.id
JOIN 
    comp_cast_type cct ON ci.person_role_id = cct.id
JOIN 
    movie_info mi ON ti.id = mi.movie_id
WHERE 
    ti.production_year > 2000
AND 
    cct.kind LIKE 'Actor%'
ORDER BY 
    ti.production_year DESC, 
    actor_name;
