SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS character_type,
    GROUP_CONCAT(DISTINCT k.keyword) AS movie_keywords,
    p.info AS actor_bio
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, c.kind, p.info
HAVING 
    COUNT(mk.keyword_id) > 5
ORDER BY 
    t.production_year DESC, actor_name;
