SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_type,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    COALESCE(MAX(m.info), 'No information available') AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, c.kind
ORDER BY 
    keyword_count DESC, actor_name ASC;
