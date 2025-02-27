SELECT 
    t.title, 
    ak.name AS aka_name, 
    c.nr_order, 
    p.info AS person_info, 
    m.info AS movie_info
FROM 
    title AS t
JOIN 
    aka_title AS ak ON t.id = ak.movie_id
JOIN 
    cast_info AS c ON ak.movie_id = c.movie_id
JOIN 
    name AS n ON c.person_id = n.id
JOIN 
    person_info AS p ON n.id = p.person_id
JOIN 
    movie_info AS m ON ak.movie_id = m.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    ak.name;
