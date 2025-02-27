SELECT 
    ak.name AS aka_name, 
    t.title AS movie_title, 
    c.kind AS cast_kind, 
    p.info AS person_info, 
    k.keyword AS movie_keyword 
FROM 
    aka_name ak 
JOIN 
    cast_info c ON ak.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    person_info p ON ak.person_id = p.person_id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND ak.name IS NOT NULL 
    AND k.keyword LIKE 'Action%' 
ORDER BY 
    ak.name, t.production_year DESC 
LIMIT 100;
