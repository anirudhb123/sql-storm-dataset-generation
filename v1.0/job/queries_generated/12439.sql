SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    c.note AS cast_note, 
    c.nr_order, 
    p.info AS personal_info, 
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
LEFT JOIN 
    person_info p ON c.person_id = p.person_id
LEFT JOIN 
    movie_keyword k ON t.movie_id = k.movie_id
WHERE 
    t.production_year >= 2000 
    AND a.name IS NOT NULL 
ORDER BY 
    t.production_year DESC, 
    c.nr_order;
