-- Performance benchmarking query joining multiple tables from the Join Order Benchmark schema

SELECT 
    t.title AS movie_title,
    an.name AS actor_name,
    ct.kind AS company_type,
    mk.keyword AS movie_keyword,
    pi.info AS person_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    aka_name an ON cc.subject_id = an.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    person_info pi ON an.person_id = pi.person_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, an.name ASC
LIMIT 100;
