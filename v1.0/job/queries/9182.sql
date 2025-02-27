SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.role_id, 
    p.info AS person_info, 
    k.keyword AS movie_keyword 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    person_info p ON a.person_id = p.person_id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND k.keyword LIKE '%Action%' 
ORDER BY 
    t.production_year DESC, 
    a.name;
