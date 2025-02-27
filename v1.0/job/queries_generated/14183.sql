SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    COUNT(DISTINCT mc.company_id) AS company_count,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
GROUP BY 
    t.title, a.name
ORDER BY 
    movie_title, actor_name;
