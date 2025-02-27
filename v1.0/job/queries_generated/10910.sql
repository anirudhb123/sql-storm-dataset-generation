SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    p.info AS person_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
INNER JOIN 
    cast_info c ON a.person_id = c.person_id
INNER JOIN 
    aka_title t ON c.movie_id = t.movie_id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_keyword k ON t.movie_id = k.movie_id
ORDER BY 
    a.name, t.production_year;
