SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.role_id, 
    ct.kind AS company_type, 
    COUNT(*) AS total_movies
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    t.production_year >= 2000
AND 
    ct.kind IN ('Distributor', 'Production')
GROUP BY 
    a.name, t.title, c.role_id, ct.kind
HAVING 
    COUNT(*) > 5
ORDER BY 
    total_movies DESC, a.name ASC
LIMIT 10;
