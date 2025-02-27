SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    ci.nr_order AS cast_order,
    p.info AS person_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    person_info p ON ak.person_id = p.person_id
WHERE 
    t.production_year = 2020
ORDER BY 
    t.title, ci.nr_order;
