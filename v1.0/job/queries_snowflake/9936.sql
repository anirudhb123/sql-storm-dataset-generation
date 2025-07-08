SELECT 
    an.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    c.role_id,
    COUNT(*) AS total_movies
FROM 
    aka_name an
JOIN 
    cast_info c ON an.person_id = c.person_id
JOIN 
    aka_title at ON c.movie_id = at.movie_id
JOIN 
    complete_cast cc ON at.id = cc.movie_id
JOIN 
    movie_companies mc ON at.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    role_type rt ON c.role_id = rt.id
WHERE 
    at.production_year >= 2000 AND 
    co.country_code = 'USA'
GROUP BY 
    an.name, at.title, at.production_year, c.role_id
HAVING 
    COUNT(*) > 1
ORDER BY 
    total_movies DESC, an.name ASC;
