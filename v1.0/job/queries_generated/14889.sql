-- Performance Benchmarking Query
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS company_type,
    ki.keyword AS movie_keyword,
    pi.info AS person_info,
    COUNT(*) AS total_roles
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
GROUP BY 
    t.title, a.name, ct.kind, ki.keyword, pi.info
ORDER BY 
    total_roles DESC;
