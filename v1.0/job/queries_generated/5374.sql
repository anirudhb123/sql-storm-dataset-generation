SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    AVG(mi.info_length) AS avg_info_length
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    (SELECT movie_id, LENGTH(info) AS info_length FROM movie_info) mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    COUNT(DISTINCT mk.keyword) > 0
ORDER BY 
    keyword_count DESC, avg_info_length ASC;
