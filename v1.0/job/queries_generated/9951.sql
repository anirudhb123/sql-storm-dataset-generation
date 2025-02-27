SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year AS release_year, 
    GROUP_CONCAT(DISTINCT r.role ORDER BY r.role) AS roles,
    COUNT(DISTINCT c.id) AS cast_count,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year > 2000
GROUP BY 
    a.id, t.id
HAVING 
    COUNT(DISTINCT r.id) > 1
ORDER BY 
    t.production_year DESC, a.name;
