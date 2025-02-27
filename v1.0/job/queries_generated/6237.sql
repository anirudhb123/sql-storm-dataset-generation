SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    COUNT(DISTINCT m.id) AS movie_count,
    COUNT(DISTINCT kw.keyword) AS keyword_count
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
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    a.name IS NOT NULL 
    AND c.kind IS NOT NULL
    AND t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    COUNT(DISTINCT kw.keyword) > 5 
ORDER BY 
    movie_count DESC, keyword_count DESC;
