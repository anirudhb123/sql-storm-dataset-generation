SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    p.info AS person_info,
    mk.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
WHERE 
    t.production_year > 2000
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
ORDER BY 
    t.production_year DESC, a.name ASC
LIMIT 100;
