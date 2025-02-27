SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    p.info AS person_info,
    mc.note AS movie_company_note
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
ORDER BY 
    a.name, t.production_year, c.nr_order;
