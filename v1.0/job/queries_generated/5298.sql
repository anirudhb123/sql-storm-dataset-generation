SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.role_id AS actor_role, 
    m.info AS movie_info, 
    k.keyword AS movie_keyword, 
    p.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000 
    AND k.keyword IS NOT NULL
ORDER BY 
    t.production_year DESC, a.name ASC
LIMIT 100;
