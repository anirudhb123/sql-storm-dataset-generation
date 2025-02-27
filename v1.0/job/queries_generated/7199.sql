SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role,
    m.info AS movie_info,
    GROUP_CONCAT(k.keyword) AS keywords
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type c ON ci.role_id = c.id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND c.role = 'actor'
GROUP BY 
    t.id, a.name, c.kind, m.info
ORDER BY 
    t.production_year DESC, a.name;
