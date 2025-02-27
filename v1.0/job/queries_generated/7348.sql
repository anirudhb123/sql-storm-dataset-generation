SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    c.kind AS cast_type,
    co.name AS company_name,
    COUNT(*) AS total_movies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.movie_id
JOIN 
    movie_companies mc ON m.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    m.production_year BETWEEN 1990 AND 2023
    AND co.country_code = 'USA'
GROUP BY 
    a.name, m.title, c.kind, co.name
ORDER BY 
    total_movies DESC
LIMIT 50;
