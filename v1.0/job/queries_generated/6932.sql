SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords, 
    COUNT(mc.company_id) AS companies_count, 
    MIN(t.production_year) AS first_movie_year, 
    MAX(t.production_year) AS last_movie_year 
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    title t ON ci.movie_id = t.id 
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id 
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id 
WHERE 
    a.name IS NOT NULL 
GROUP BY 
    a.name, t.title 
HAVING 
    COUNT(mc.company_id) > 1 
ORDER BY 
    last_movie_year DESC, actor_name ASC 
LIMIT 100;
