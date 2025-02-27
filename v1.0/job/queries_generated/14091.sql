SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    n.name AS actor_name,
    c.note AS cast_note,
    p.info AS person_info,
    k.keyword AS movie_keyword
FROM 
    aka_title a
JOIN 
    title t ON a.movie_id = t.id
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name n ON c.person_id = n.person_id
JOIN 
    person_info p ON n.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, 
    c.nr_order;
