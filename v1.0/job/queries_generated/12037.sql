-- SQL query for performance benchmarking on Join Order Benchmark schema
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    p.info AS person_info
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    aka_name a ON cc.subject_id = a.person_id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000
    AND c.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
