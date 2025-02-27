-- Performance Benchmarking SQL Query using Join Order Benchmark schema

SELECT
    a.name AS aka_name,
    t.title AS movie_title,
    p.info AS person_info,
    c.kind AS comp_cast_type,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    r.role AS role_type
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    title t ON ci.movie_id = t.id
JOIN
    person_info p ON a.person_id = p.person_id
JOIN
    complete_cast cc ON t.id = cc.movie_id
JOIN
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
WHERE
    t.production_year >= 2000
ORDER BY
    t.production_year DESC, a.name;
