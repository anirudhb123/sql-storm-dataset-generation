SELECT 
    ak.name AS aka_name, 
    t.title AS movie_title, 
    p.name AS person_name, 
    ct.kind AS cast_type
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    comp_cast_type cct ON ci.person_role_id = cct.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
