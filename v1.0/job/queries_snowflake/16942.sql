SELECT 
    n.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order
FROM 
    cast_info c
JOIN 
    aka_name n ON c.person_id = n.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
WHERE 
    t.production_year = 2020
ORDER BY 
    c.nr_order;
