SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    c.nr_order, 
    n.name AS person_name 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    name n ON a.person_id = n.imdb_id 
WHERE 
    t.production_year > 2000 
ORDER BY 
    t.production_year DESC, 
    c.nr_order;
