SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    COUNT(DISTINCT c.id) AS cast_count,
    COUNT(DISTINCT m.id) AS company_count
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info c ON at.movie_id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    t.title, a.name
ORDER BY 
    movie_title ASC, actor_name ASC;
