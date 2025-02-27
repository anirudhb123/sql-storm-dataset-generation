
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    m.info AS movie_info,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    r.role AS role,
    COUNT(DISTINCT cc.id) AS complete_cast_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
WHERE 
    a.name IS NOT NULL
    AND t.production_year BETWEEN 2000 AND 2023
    AND m.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%award%')
GROUP BY 
    a.name, t.title, m.info, r.role
HAVING 
    COUNT(DISTINCT k.id) > 2
ORDER BY 
    complete_cast_count DESC, t.title;
