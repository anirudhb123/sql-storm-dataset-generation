SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    ct.kind AS company_type,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    COUNT(DISTINCT mk.keyword) AS num_keywords,
    COUNT(DISTINCT pi.info) AS num_person_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id
WHERE 
    t.production_year >= 2000
GROUP BY 
    t.title, a.name, ct.kind
ORDER BY 
    num_companies DESC, num_keywords DESC, num_person_info DESC;
