-- Performance benchmark query to analyze join performance between key tables in the benchmark schema.
SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    p.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    title ti ON t.movie_id = ti.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    ti.production_year BETWEEN 2000 AND 2020
ORDER BY 
    ti.production_year, c.nr_order;
