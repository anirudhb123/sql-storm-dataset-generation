SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    COUNT(k.keyword) AS keyword_count,
    MIN(mi.info) AS first_info,
    MAX(mi.info) AS last_info
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
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    COUNT(k.keyword) > 2 AND MIN(mi.info) IS NOT NULL
ORDER BY 
    keyword_count DESC, movie_title ASC
LIMIT 10;
