SELECT 
    a.name as actor_name,
    t.title as movie_title,
    c.nr_order as cast_order
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
WHERE 
    t.production_year = 2020
ORDER BY 
    c.nr_order;
