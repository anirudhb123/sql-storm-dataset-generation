SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS company_type,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    MAX(mi.info) AS most_recent_info
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
GROUP BY 
    t.title, a.name, c.kind
HAVING 
    COUNT(DISTINCT mk.keyword) > 5
ORDER BY 
    keyword_count DESC, movie_title;
