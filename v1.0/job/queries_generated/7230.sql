SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS character_role,
    co.name AS company_name,
    ct.kind AS company_type,
    ti.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type cr ON ci.role_id = cr.id
WHERE 
    t.production_year > 2000
    AND k.keyword ILIKE '%action%'
    AND it.info ILIKE '%great%'
ORDER BY 
    a.name, t.production_year DESC;
