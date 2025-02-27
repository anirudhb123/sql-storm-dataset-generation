SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS role_order,
    p.info AS person_info,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_info m ON c.movie_id = m.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, c.nr_order;
