-- Performance benchmarking query for Join Order Benchmark schema

SELECT 
    t.title AS movie_title,
    ak.name AS aka_name,
    c.name AS character_name,
    p.info AS person_info,
    m.name AS company_name,
    k.keyword AS movie_keyword,
    r.role AS role_type,
    co.kind AS company_type
FROM 
    title t
JOIN 
    aka_title ak ON t.id = ak.movie_id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    name n ON ci.person_id = n.id
JOIN 
    person_info p ON n.id = p.person_id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    company_type co ON mc.company_type_id = co.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
