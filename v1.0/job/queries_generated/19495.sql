SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    c.nr_order AS role_order,
    p.info AS actor_info
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
JOIN 
    person_info p ON c.person_id = p.person_id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, 
    c.nr_order ASC;
