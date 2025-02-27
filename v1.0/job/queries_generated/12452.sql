-- Performance Benchmarking Query for Join Order
SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS actor_name,
    ct.kind AS cast_type,
    c.name AS company_name,
    m.info AS movie_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
JOIN 
    role_type AS ct ON ci.role_id = ct.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS c ON mc.company_id = c.id
JOIN 
    movie_info AS m ON t.id = m.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
