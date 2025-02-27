-- Performance Benchmarking SQL Query
SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    t.id AS title_id,
    t.title AS movie_title,
    ci.id AS cast_id,
    cn.name AS company_name,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
