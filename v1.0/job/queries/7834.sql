SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    p.info AS actor_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
AND 
    k.keyword LIKE '%action%'
ORDER BY 
    t.production_year DESC, a.name;
