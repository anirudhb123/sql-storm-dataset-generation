-- Performance benchmarking query for Join Order Benchmark schema

SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    cc.kind AS company_type,
    k.keyword AS movie_keyword,
    p.info AS person_info,
    r.role AS role_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type cc ON mc.company_type_id = cc.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON c.person_id = p.person_id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
