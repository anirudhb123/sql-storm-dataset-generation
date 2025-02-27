SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    COUNT(DISTINCT pi.info) AS info_count
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
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    t.production_year >= 2000
    AND c.kind ILIKE '%production%'
GROUP BY 
    a.name, t.title, c.kind
ORDER BY 
    keyword_count DESC, info_count DESC
LIMIT 50;
