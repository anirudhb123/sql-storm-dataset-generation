
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    kt.kind AS cast_type, 
    co.name AS company_name, 
    COUNT(*) AS total_movies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    kind_type kt ON mc.company_type_id = kt.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year > 2000 
    AND kt.kind = 'Production'
GROUP BY 
    a.name, t.title, kt.kind, co.name
HAVING 
    COUNT(*) > 1
ORDER BY 
    total_movies DESC
LIMIT 10;
