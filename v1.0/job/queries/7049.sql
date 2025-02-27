
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords, 
    c.name AS company_name, 
    cp.kind AS company_type,
    COUNT(DISTINCT ci.movie_id) AS total_movies 
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    aka_title t ON ci.movie_id = t.movie_id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name c ON mc.company_id = c.id 
JOIN 
    company_type cp ON mc.company_type_id = cp.id 
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id 
WHERE 
    a.name IS NOT NULL 
    AND t.production_year BETWEEN 2000 AND 2023 
GROUP BY 
    a.name, t.title, t.production_year, c.name, cp.kind 
ORDER BY 
    total_movies DESC, t.production_year DESC 
LIMIT 50;
