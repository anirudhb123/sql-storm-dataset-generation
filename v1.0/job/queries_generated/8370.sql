SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    c.kind AS cast_type,
    p.info AS person_info,
    k.keyword AS film_keyword
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    person_info p ON ak.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND ak.name LIKE 'A%'
    AND k.keyword IS NOT NULL
ORDER BY 
    t.production_year DESC, 
    ak.name;
