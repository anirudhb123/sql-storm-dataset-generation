SELECT 
    a.id AS aka_id, 
    a.name AS aka_name, 
    t.title AS movie_title, 
    p.info AS person_info, 
    c.kind AS cast_type, 
    m.info AS movie_info, 
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000 
    AND a.name IS NOT NULL 
    AND k.keyword IS NOT NULL
ORDER BY 
    t.production_year DESC, a.name ASC;
