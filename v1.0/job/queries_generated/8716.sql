SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id AS role_id,
    COUNT(DISTINCT m.id) AS total_movies,
    STRING_AGG(DISTINCT m.keyword, ', ') AS keywords,
    AVG(CASE WHEN ti.info_type_id IS NOT NULL THEN 1 ELSE 0 END) * 100 AS info_availability_percentage
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword m ON mk.keyword_id = m.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year >= 2000
GROUP BY 
    a.name, t.title, c.role_id
ORDER BY 
    total_movies DESC, actor_name ASC
LIMIT 100;
