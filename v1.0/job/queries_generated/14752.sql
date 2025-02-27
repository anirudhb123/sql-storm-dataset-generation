-- Performance Benchmarking Query for Join Order Benchmark schema

SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    c.role_id AS role,
    ct.kind AS comp_cast_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    comp_cast_type ct ON c.person_role_id = ct.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    p.gender = 'F'
ORDER BY 
    t.production_year DESC, a.name;
