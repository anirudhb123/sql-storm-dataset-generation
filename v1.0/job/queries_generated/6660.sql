SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    p.info AS actor_info,
    n.name AS character_name,
    COUNT(k.keyword) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    char_name n ON ci.role_id = n.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
    AND c.kind IS NOT NULL
GROUP BY 
    a.name, t.title, c.kind, p.info, n.name
HAVING 
    COUNT(k.keyword) > 3
ORDER BY 
    keyword_count DESC, a.name ASC;
