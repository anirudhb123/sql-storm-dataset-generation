-- Performance Benchmarking Query for Join Order Benchmark schema
SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.id AS cast_id,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    mi.info AS movie_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    aka_title AS t ON c.movie_id = t.movie_id
JOIN 
    person_info AS p ON c.person_id = p.person_id
JOIN 
    movie_keyword AS mk ON t.movie_id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    movie_companies AS mc ON t.movie_id = mc.movie_id
JOIN 
    company_name AS co ON mc.company_id = co.id
JOIN 
    movie_info AS mi ON t.movie_id = mi.movie_id
WHERE 
    a.name IS NOT NULL
AND 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
