-- Performance Benchmarking Query
SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    ci.nr_order AS cast_order,
    cn.name AS company_name,
    kt.keyword AS movie_keyword,
    pi.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
JOIN 
    person_info pi ON a.person_id = pi.person_id
ORDER BY 
    t.production_year DESC, ci.nr_order ASC;
