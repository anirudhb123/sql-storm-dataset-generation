SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    ci.nr_order AS cast_order, 
    pc.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    person_info pc ON a.person_id = pc.person_id
WHERE 
    t.production_year = 2023
ORDER BY 
    ci.nr_order;
