SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS company_type,
    m.info AS movie_info,
    COUNT(DISTINCT mk.keyword) AS keyword_count
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
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND a.name LIKE 'A%'
    AND m.info_type_id IN (SELECT id FROM info_type WHERE info = 'budget')
GROUP BY 
    a.name, t.title, c.kind, m.info
ORDER BY 
    keyword_count DESC, a.name;
