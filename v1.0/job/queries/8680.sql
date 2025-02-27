SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    co.name AS company_name,
    ct.kind AS company_type,
    k.keyword AS movie_keyword,
    pi.info AS person_info,
    COUNT(DISTINCT c.id) AS cast_count
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    t.production_year >= 2000
    AND ct.kind = 'Distributor'
GROUP BY 
    t.title, a.name, co.name, ct.kind, k.keyword, pi.info
ORDER BY 
    cast_count DESC, t.title;
