SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    ci.person_role_id,
    ci.nr_order,
    c.name AS company_name,
    rt.role AS role_type,
    mi.info AS movie_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    ak.name;
