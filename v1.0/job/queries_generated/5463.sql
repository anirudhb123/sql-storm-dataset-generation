SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_type,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT co.name) AS production_companies,
    COUNT(DISTINCT m.id) AS movie_count
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
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    COUNT(DISTINCT m.id) > 5
ORDER BY 
    movie_count DESC, actor_name ASC;
