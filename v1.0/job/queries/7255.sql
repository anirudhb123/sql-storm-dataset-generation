SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.role_id AS role_id, 
    p.info AS person_info, 
    kc.keyword AS keyword 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    aka_title t ON c.movie_id = t.movie_id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword kc ON mk.keyword_id = kc.id 
JOIN 
    person_info p ON a.person_id = p.person_id 
WHERE 
    t.production_year >= 2000 
    AND kc.keyword LIKE '%action%' 
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography') 
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
