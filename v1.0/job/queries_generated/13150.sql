-- Performance Benchmarking Query

SELECT 
    p.id AS person_id,
    p.name AS person_name,
    t.title AS movie_title,
    c.role_id,
    mk.keyword AS movie_keyword,
    co.name AS company_name,
    ct.kind AS company_type,
    mi.info AS movie_info
FROM 
    aka_name p
JOIN 
    cast_info ci ON p.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    p.name IS NOT NULL
AND 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, p.name;
