SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    c.nr_order AS cast_order, 
    p.info AS person_info, 
    k.keyword AS movie_keyword 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    aka_title t ON c.movie_id = t.movie_id 
JOIN 
    person_info p ON a.person_id = p.person_id 
JOIN 
    movie_keyword k ON c.movie_id = k.movie_id 
WHERE 
    t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
    AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'birth date') 
ORDER BY 
    t.production_year, c.nr_order;
