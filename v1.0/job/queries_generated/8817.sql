SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    COUNT(DISTINCT kc.keyword) AS total_keywords,
    COUNT(DISTINCT pi.info) AS total_person_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    COUNT(DISTINCT kc.keyword) > 0 
    AND COUNT(DISTINCT pi.info) > 1
ORDER BY 
    total_keywords DESC, actor_name ASC;
