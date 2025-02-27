-- Performance benchmarking query for Join Order Benchmark schema

SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    rc.role AS role,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    title t 
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type rc ON ci.role_id = rc.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
