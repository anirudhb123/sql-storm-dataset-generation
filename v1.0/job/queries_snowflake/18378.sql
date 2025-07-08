SELECT 
    p.name AS person_name,
    t.title AS movie_title,
    c.nr_order AS role_order
FROM 
    cast_info c
JOIN 
    aka_name p ON c.person_id = p.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
WHERE 
    t.production_year = 2021
ORDER BY 
    c.nr_order;
