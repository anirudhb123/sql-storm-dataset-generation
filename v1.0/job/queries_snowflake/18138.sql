SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
ORDER BY 
    t.production_year DESC, 
    c.nr_order;
