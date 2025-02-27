SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    ct.kind AS cast_type,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    comp_cast_type ct ON c.person_role_id = ct.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND ct.kind = 'actor'
    AND m.info_type_id IN (SELECT id FROM info_type WHERE info = 'Budget')
ORDER BY 
    t.production_year DESC, 
    a.name, 
    c.nr_order;
