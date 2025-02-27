-- Performance benchmarking query using the Join Order Benchmark schema
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS role_type,
    cn.name AS company_name
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    aka_title AS t ON ci.movie_id = t.movie_id
JOIN 
    role_type AS c ON ci.role_id = c.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
