SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS company_type, 
    r.role AS role_type, 
    COUNT(DISTINCT m.id) AS total_movies, 
    AVG(m.production_year) AS average_production_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    r.role LIKE '%actor%'
    AND c.country_code = 'US'
    AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
GROUP BY 
    a.name, t.title, c.kind, r.role
HAVING 
    COUNT(DISTINCT t.id) > 5
ORDER BY 
    total_movies DESC, average_production_year ASC
LIMIT 10;
