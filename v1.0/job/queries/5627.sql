SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS company_type, 
    COUNT(DISTINCT c.id) AS number_of_companies, 
    MAX(mi.info) AS movie_info
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    aka_title t ON ci.movie_id = t.movie_id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_type c ON mc.company_type_id = c.id 
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id 
WHERE 
    a.name ILIKE '%Smith%' 
    AND t.production_year BETWEEN 2000 AND 2020 
    AND c.kind IN (SELECT kind FROM company_type WHERE kind LIKE 'Production%')
GROUP BY 
    a.name, t.title, c.kind 
ORDER BY 
    number_of_companies DESC, 
    movie_title ASC 
LIMIT 10;
