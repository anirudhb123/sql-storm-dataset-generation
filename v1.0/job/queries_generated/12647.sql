SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    rt.role AS role_name,
    cct.kind AS cast_type,
    co.name AS company_name,
    mt.info AS movie_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mt ON t.id = mt.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, ak.name;
