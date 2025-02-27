SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    pc.nb_order AS cast_order
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    title AS t ON c.movie_id = t.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, 
    c.nr_order ASC;
