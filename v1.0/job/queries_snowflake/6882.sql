SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    c.kind AS company_type, 
    COUNT(DISTINCT m.id) AS num_movies, 
    SUM(m.info_type_id) AS total_info_types
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    m.info_type_id IN (SELECT id FROM info_type WHERE info LIKE 'Awards%')
GROUP BY 
    a.name, t.title, t.production_year, c.kind
ORDER BY 
    num_movies DESC, total_info_types ASC
LIMIT 50;
