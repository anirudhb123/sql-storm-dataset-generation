SELECT 
    t.title, 
    a.name AS actor_name, 
    c.nr_order, 
    p.info AS person_info
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    cast_info c ON mc.movie_id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year = 2023
ORDER BY 
    t.title, c.nr_order;
