SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    p.info AS person_info, 
    k.keyword AS movie_keyword 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    aka_title t ON c.movie_id = t.movie_id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
LEFT JOIN 
    person_info p ON a.person_id = p.person_id 
WHERE 
    t.production_year >= 2000 
    AND a.name IS NOT NULL 
    AND k.keyword IS NOT NULL 
ORDER BY 
    t.production_year DESC, a.name;
