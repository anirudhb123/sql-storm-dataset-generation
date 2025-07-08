SELECT 
    a.id AS aka_name_id,
    a.name AS aka_name,
    t.id AS title_id,
    t.title AS movie_title,
    c.id AS cast_info_id,
    c.nr_order AS cast_order,
    p.id AS person_id,
    p.name AS person_name
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    name p ON a.person_id = p.imdb_id
WHERE 
    t.production_year = 2022
ORDER BY 
    t.title, c.nr_order;
