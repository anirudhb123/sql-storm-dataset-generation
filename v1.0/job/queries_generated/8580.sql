SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    COUNT(DISTINCT mc.company_id) AS company_count,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count,
    MIN(mi.info) AS min_info,
    MAX(mi.info) AS max_info
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
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name IS NOT NULL AND
    t.production_year > 2000
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    COUNT(DISTINCT mc.company_id) > 1 AND
    COUNT(DISTINCT mk.keyword_id) > 5
ORDER BY 
    actor_name, movie_title;
