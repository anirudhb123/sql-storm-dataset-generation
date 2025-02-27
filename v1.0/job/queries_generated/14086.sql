-- Performance Benchmarking Query using Join Order Benchmark Schema

SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_type,
    p.info AS person_info,
    m.info AS movie_info
FROM 
    aka_title AS t
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    role_type AS c ON ci.role_id = c.id
LEFT JOIN 
    person_info AS p ON a.person_id = p.person_id
LEFT JOIN 
    movie_info AS m ON t.id = m.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
