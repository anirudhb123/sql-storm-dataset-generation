SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ci.nr_order AS actor_order,
    c.name AS company_name,
    rt.role AS role,
    i.info AS movie_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
AND 
    c.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    actor_order ASC
LIMIT 100;
