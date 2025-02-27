SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.role_id,
    COUNT(DISTINCT m.id) AS num_movies,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword m ON t.id = m.movie_id
LEFT JOIN 
    keyword k ON m.keyword_id = k.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year >= 2000
GROUP BY 
    a.id, t.id, c.role_id
ORDER BY 
    num_movies DESC,
    actor_name ASC;
