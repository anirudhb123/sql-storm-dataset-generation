SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    p.info AS person_info,
    c.kind AS cast_kind,
    k.keyword AS movie_keyword
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    person_info p ON ak.person_id = p.person_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND c.kind LIKE 'Actor%'
ORDER BY 
    t.production_year DESC, ak.name;
