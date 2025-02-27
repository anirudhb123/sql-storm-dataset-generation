SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    c.nr_order AS cast_order, 
    m.info AS movie_additional_info, 
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_info m ON t.movie_id = m.movie_id
JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000 
    AND (m.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%award%'))
ORDER BY 
    t.production_year DESC, 
    c.nr_order ASC;
