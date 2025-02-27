SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    ci.nr_order AS cast_order,
    c.name AS company_name,
    k.keyword AS movie_keyword,
    ti.info AS additional_info,
    rr.role AS role_type
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
JOIN 
    role_type rr ON ci.role_id = rr.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND c.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    ci.nr_order ASC
LIMIT 100;
