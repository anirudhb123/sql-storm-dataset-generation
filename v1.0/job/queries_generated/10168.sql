SELECT 
    n.name AS actor_name,
    t.title AS movie_title,
    c.note AS role_note,
    c.nr_order AS role_order,
    p.info AS person_info,
    k.keyword AS movie_keyword
FROM 
    cast_info c
JOIN 
    aka_name n ON c.person_id = n.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    person_info p ON c.person_id = p.person_id
JOIN 
    movie_keyword mk ON c.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, c.nr_order;
