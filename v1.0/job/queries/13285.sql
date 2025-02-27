SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.role_id AS role_id, 
    k.keyword AS keyword, 
    p.info AS person_info
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON a.id = p.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    a.name, t.title;
