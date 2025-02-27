SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    tc.kind AS company_type,
    COUNT(*) AS total_movies
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_type tc ON mc.company_type_id = tc.id 
WHERE 
    t.production_year >= 2000 
    AND tc.kind IN ('Production', 'Distributor') 
GROUP BY 
    a.name, t.title, tc.kind 
HAVING 
    COUNT(*) > 1 
ORDER BY 
    total_movies DESC 
LIMIT 10;
