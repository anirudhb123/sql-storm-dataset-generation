SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role AS character_name,
    cc.kind AS company_type,
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
    company_type cc ON mc.company_type_id = cc.id
GROUP BY 
    a.name, t.title, c.role, cc.kind
ORDER BY 
    total_movies DESC;
