SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    c.kind AS company_type, 
    COUNT(mk.keyword_id) AS keyword_count 
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
WHERE 
    a.name IS NOT NULL 
    AND t.production_year >= 2000 
GROUP BY 
    a.name, t.title, t.production_year, c.kind 
ORDER BY 
    keyword_count DESC, t.production_year ASC 
LIMIT 10;
