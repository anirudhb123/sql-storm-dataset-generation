
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    p.info AS actor_info,
    COUNT(DISTINCT t.id) AS movie_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000 
    AND c.kind LIKE 'Production%'
GROUP BY 
    a.name, t.title, c.kind, p.info
HAVING 
    COUNT(DISTINCT t.id) > 5
ORDER BY 
    movie_count DESC;
