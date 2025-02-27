-- Performance Benchmarking Query for Join Order Scenario

SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    t.id AS title_id,
    t.title AS title_name,
    c.person_role_id,
    c.nr_order,
    p.info AS person_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000 
    AND c.nr_order < 5
ORDER BY 
    t.production_year DESC, c.nr_order;
