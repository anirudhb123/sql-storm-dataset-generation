-- Performance Benchmark Query for Join Order
SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    ci.note AS cast_note,
    p.info AS person_info,
    kt.keyword AS movie_keyword,
    c.name AS company_name,
    rt.role AS role_type
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
