SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order,
    ct.kind AS company_type
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    t.production_year = 2023
ORDER BY 
    t.title;
