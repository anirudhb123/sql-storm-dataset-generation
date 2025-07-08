SELECT 
    a.id AS aka_id, 
    a.name AS aka_name, 
    t.title AS movie_title, 
    t.production_year, 
    c.nr_order AS cast_order, 
    r.role AS person_role, 
    pn.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    person_info pn ON a.person_id = pn.person_id AND pn.info_type_id = 1
WHERE 
    t.production_year >= 2000 
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
ORDER BY 
    t.production_year DESC, 
    a.name;
