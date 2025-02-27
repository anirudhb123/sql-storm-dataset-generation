SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    c.nr_order AS cast_order, 
    k.keyword AS movie_keyword, 
    p.info AS person_info
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
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, 
    c.nr_order;
