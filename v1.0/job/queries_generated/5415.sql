SELECT 
    ak.name AS actor_name,
    ak.id AS actor_id,
    ti.title AS movie_title,
    ti.production_year,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    COUNT(DISTINCT mk.keyword_id) AS movie_keywords
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title ti ON ci.movie_id = ti.id
LEFT JOIN 
    movie_companies mc ON ti.id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON ti.id = mk.movie_id
WHERE 
    ti.production_year >= 2000
    AND ak.name IS NOT NULL
GROUP BY 
    ak.id, ak.name, ti.title, ti.production_year
ORDER BY 
    production_companies DESC, movie_title ASC
LIMIT 100;
