-- Performance Benchmarking Query using Join Order Benchmark schema

SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    s.kind AS company_type,
    it.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    company_type s ON mc.company_type_id = s.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    a.name IS NOT NULL
AND 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
