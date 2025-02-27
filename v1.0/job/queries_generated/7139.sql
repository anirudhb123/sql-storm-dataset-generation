SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    COUNT(m.movie_id) AS total_movies
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
WHERE 
    a.name LIKE 'A%' 
    AND t.production_year > 2000
GROUP BY 
    a.name, t.title, c.kind
ORDER BY 
    total_movies DESC
LIMIT 10;
