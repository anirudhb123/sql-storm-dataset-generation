SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.role_id, 
    COUNT(DISTINCT k.keyword) AS keyword_count,
    MIN(m.production_year) AS earliest_production_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    a.name IS NOT NULL
    AND t.production_year >= 2000
GROUP BY 
    a.name, t.title, c.role_id
HAVING 
    COUNT(DISTINCT k.keyword) > 2
ORDER BY 
    earliest_production_year DESC, actor_name ASC;
