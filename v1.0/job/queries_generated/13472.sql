-- Performance Benchmarking Query for Join Order Benchmark Schema
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_type,
    p.info AS actor_info,
    co.name AS company_name
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON ci.movie_id = t.id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    role_type c ON ci.role_id = c.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.id
LEFT JOIN 
    company_name co ON co.id = mc.company_id
LEFT JOIN 
    person_info p ON p.person_id = a.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.title, a.name;
