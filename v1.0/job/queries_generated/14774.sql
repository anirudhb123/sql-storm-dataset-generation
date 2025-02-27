SELECT 
    na.name AS actor_name,
    ti.title AS movie_title,
    ti.production_year,
    ci.nr_order AS role_order,
    rt.role AS role_name,
    co.name AS company_name
FROM 
    cast_info ci
JOIN 
    aka_name na ON ci.person_id = na.person_id
JOIN 
    aka_title ti ON ci.movie_id = ti.movie_id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
WHERE 
    ti.production_year >= 2000
ORDER BY 
    ti.production_year DESC, 
    na.name;
