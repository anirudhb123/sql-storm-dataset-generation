SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    pi.info AS person_info,
    COUNT(DISTINCT cc.subject_id) AS total_casts
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    keyword k ON t.id = k.movie_id
JOIN 
    person_info pi ON a.person_id = pi.person_id
JOIN 
    complete_cast cc ON cc.movie_id = t.id
WHERE 
    t.production_year >= 2000
    AND ct.kind = 'Producer'
    AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
GROUP BY 
    a.name, t.title, ct.kind, k.keyword, pi.info
ORDER BY 
    total_casts DESC, a.name;
