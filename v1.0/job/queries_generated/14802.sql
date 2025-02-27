-- Performance benchmarking query joining several tables in the Join Order Benchmark schema

SELECT 
    t.title AS movie_title,
    p.name AS person_name,
    r.role AS role_name,
    c.kind AS comp_cast_type,
    mi.info AS movie_info
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, t.title;
