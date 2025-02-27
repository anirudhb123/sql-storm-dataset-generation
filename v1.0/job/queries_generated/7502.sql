SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.role_id AS role_id, 
    r.role AS role_name, 
    COUNT(mk.keyword) AS keyword_count, 
    GROUP_CONCAT(mk.keyword) AS keywords
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
GROUP BY 
    a.name, t.title, c.role_id, r.role
HAVING 
    COUNT(mk.keyword) > 1
ORDER BY 
    keyword_count DESC, actor_name ASC;
