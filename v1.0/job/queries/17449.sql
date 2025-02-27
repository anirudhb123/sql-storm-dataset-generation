SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    ci.kind AS company_type
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ci ON mc.company_type_id = ci.id
WHERE 
    t.production_year = 2021
ORDER BY 
    c.nr_order;
