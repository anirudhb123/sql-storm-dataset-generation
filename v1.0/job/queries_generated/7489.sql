SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS company_type,
    COUNT(DISTINCT m.keyword_id) AS total_keywords,
    STRING_AGG(DISTINCT m.keyword, ', ') AS keywords
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
    movie_keyword m ON t.id = m.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND c.kind IN ('Distributor', 'Production')
GROUP BY 
    a.name, t.title, t.production_year, c.kind
ORDER BY 
    total_keywords DESC, t.production_year DESC;
