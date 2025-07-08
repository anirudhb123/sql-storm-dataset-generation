
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    ct.kind AS company_type,
    pi.info AS person_info,
    COUNT(mk.id) AS keyword_count
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
    person_info pi ON a.person_id = pi.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
WHERE 
    t.production_year >= 2000 
    AND pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
GROUP BY 
    a.name, t.title, ct.kind, pi.info
ORDER BY 
    keyword_count DESC, a.name ASC;
