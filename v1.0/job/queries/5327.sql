SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ci.nr_order AS character_order,
    comp.name AS company_name,
    kt.keyword AS movie_keyword,
    ti.info AS movie_info,
    r.role AS role_type
FROM 
    aka_title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND comp.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
