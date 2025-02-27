SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS company_type,
    k.keyword AS movie_keyword,
    p.info AS person_info,
    COUNT(DISTINCT mc.company_id) AS company_count
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
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year > 2000
    AND ct.kind ILIKE '%production%'
GROUP BY 
    t.title, a.name, ct.kind, k.keyword, p.info
ORDER BY 
    company_count DESC, movie_title ASC;
