SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS company_type, 
    COUNT(mk.keyword) AS keyword_count,
    GROUP_CONCAT(DISTINCT mk.keyword) AS keywords,
    t.production_year 
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
WHERE 
    t.production_year >= 2000 
    AND c.kind ILIKE '%production%' 
GROUP BY 
    a.name, t.title, c.kind, t.production_year 
HAVING 
    COUNT(mk.keyword) > 2 
ORDER BY 
    t.production_year DESC, actor_name ASC;
