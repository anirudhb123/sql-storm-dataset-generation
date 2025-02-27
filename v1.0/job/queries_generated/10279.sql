SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    p.gender AS actor_gender,
    c.kind AS company_type,
    COUNT(DISTINCT m.id) AS total_movies,
    AVG(m.production_year) AS avg_production_year
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    name p ON a.person_id = p.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    c.country_code = 'USA'
    AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'box office')
GROUP BY 
    t.title, a.name, p.gender, c.kind
ORDER BY 
    total_movies DESC;
