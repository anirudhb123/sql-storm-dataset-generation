SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    m.info AS movie_info
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_info m ON c.movie_id = m.movie_id
WHERE 
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
ORDER BY 
    t.production_year DESC, 
    c.nr_order;
