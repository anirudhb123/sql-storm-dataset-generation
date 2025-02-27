SELECT 
    a.id AS aka_id, 
    a.name AS aka_name, 
    t.title AS movie_title, 
    k.keyword AS movie_keyword, 
    ci.role_id AS cast_role_id, 
    pt.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info pt ON a.person_id = pt.person_id
WHERE 
    t.production_year > 2000 
    AND pt.info_type_id = (SELECT id FROM info_type WHERE info = 'birth date')
ORDER BY 
    t.production_year DESC, 
    a.name ASC 
LIMIT 100;
