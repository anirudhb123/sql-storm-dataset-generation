SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.role_id,
    p.info AS person_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.id
JOIN 
    person_info p ON c.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL
ORDER BY 
    t.production_year DESC, a.name;
