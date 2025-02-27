SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    COUNT(DISTINCT m.id) AS total_movies,
    AVG(mi.info_length) AS average_info_length
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    COUNT(DISTINCT m.id) > 5
ORDER BY 
    total_movies DESC, actor_name ASC
LIMIT 10;
