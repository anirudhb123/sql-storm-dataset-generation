SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.role_id AS role_id, 
    k.keyword AS movie_keyword, 
    p.info AS person_info, 
    cc.kind AS comp_cast_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
WHERE 
    t.production_year >= 2000 
    AND a.name ILIKE '%Smith%' 
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
