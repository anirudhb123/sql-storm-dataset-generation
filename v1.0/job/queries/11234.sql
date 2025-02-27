SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    r.role AS role_type,
    tn.info AS additional_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    movie_info tn ON t.id = tn.movie_id AND tn.info_type_id = (SELECT id FROM info_type WHERE info = 'some_info_type')
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
