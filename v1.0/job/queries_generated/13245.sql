SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    ci.nr_order AS role_order,
    rt.role AS role_type,
    c.name AS company_name,
    c.country_code AS company_country,
    ti.info AS movie_info
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year, ak.name;
