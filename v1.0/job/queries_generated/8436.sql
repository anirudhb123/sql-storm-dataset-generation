SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    COUNT(*) AS role_count,
    SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS trivia_count,
    ARRAY_AGG(DISTINCT kw.keyword) AS keywords
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
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year >= 2000
    AND c.kind IS NOT NULL
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    COUNT(*) > 0
ORDER BY 
    role_count DESC, actor_name ASC;
