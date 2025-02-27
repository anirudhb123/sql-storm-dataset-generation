-- Performance Benchmarking SQL Query using Join Order Benchmark schema

SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    c.role_id,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    ti.info AS movie_info,
    rt.role AS role_description
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    name p ON c.person_id = p.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
JOIN 
    role_type rt ON c.role_id = rt.id
ORDER BY 
    t.production_year DESC, t.title ASC;
