SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    COUNT(DISTINCT m.keyword_id) AS keyword_count,
    MAX(CASE WHEN i.info_type_id = 1 THEN i.info END) AS movie_tagline,
    MAX(CASE WHEN i.info_type_id = 2 THEN i.info END) AS movie_synopsis
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword m ON t.id = m.movie_id
JOIN 
    movie_info i ON t.id = i.movie_id
WHERE 
    t.production_year > 2000
    AND c.kind LIKE 'Production%'
GROUP BY 
    a.name, t.title, c.kind
ORDER BY 
    keyword_count DESC, a.name, t.title
LIMIT 50;
