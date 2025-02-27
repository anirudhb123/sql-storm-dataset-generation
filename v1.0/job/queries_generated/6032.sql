SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    p.info AS actor_info,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    c.kind AS company_type
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND a.name IS NOT NULL
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info LIKE 'bio%')
GROUP BY 
    t.title, a.name, p.info, c.kind
ORDER BY 
    keyword_count DESC, t.title ASC
LIMIT 100;
