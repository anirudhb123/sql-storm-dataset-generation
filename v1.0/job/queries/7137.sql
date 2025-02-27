SELECT 
    c.person_id, 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    COUNT(*) AS role_count
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    complete_cast cc ON c.movie_id = cc.movie_id
JOIN 
    movie_info mi ON cc.movie_id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND it.info = 'Box Office'
GROUP BY 
    c.person_id, a.name, t.title, t.production_year
HAVING 
    COUNT(*) > 1
ORDER BY 
    role_count DESC, actor_name ASC;
