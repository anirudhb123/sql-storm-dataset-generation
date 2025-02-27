SELECT 
    a.name AS alias_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    p.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    person_info p ON c.person_id = p.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year, c.nr_order;
