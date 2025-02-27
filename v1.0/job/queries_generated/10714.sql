SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    ak.id AS actor_id,
    ci.nr_order AS role_order,
    rt.role AS role_type
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    ak.name;
