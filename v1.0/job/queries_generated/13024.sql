SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    r.role AS person_role,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    name p ON ci.person_id = p.id
JOIN 
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
