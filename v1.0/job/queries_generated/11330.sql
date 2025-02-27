SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.nr_order AS role_order,
    r.role AS role_name,
    p.info AS person_info,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    person_info p ON c.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
