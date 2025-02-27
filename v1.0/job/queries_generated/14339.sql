-- Benchmark query to evaluate the performance of join operations across related tables
SELECT 
    a.name AS aka_name, 
    t.title AS movie_title,
    c.nr_order AS cast_order,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    comp.name AS company_name,
    ct.kind AS company_type,
    mt.kind AS movie_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    title mt ON t.movie_id = mt.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
ORDER BY 
    t.production_year DESC, 
    a.name;
