
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    COUNT(DISTINCT m.id) AS movie_count,
    AVG(m.production_year) AS average_production_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    title m ON t.id = m.id
WHERE 
    a.name IS NOT NULL 
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    COUNT(DISTINCT m.id) > 5
ORDER BY 
    average_production_year DESC, movie_count DESC;
