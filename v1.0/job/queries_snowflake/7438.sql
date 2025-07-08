SELECT 
    a.id AS aka_id, 
    a.name AS aka_name, 
    t.title AS movie_title, 
    p.name AS person_name, 
    c.kind AS cast_type, 
    m.info AS movie_info 
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    title t ON ci.movie_id = t.id 
JOIN 
    name p ON a.person_id = p.imdb_id 
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id 
JOIN 
    movie_info m ON t.id = m.movie_id 
WHERE 
    t.production_year >= 2000 
    AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards') 
    AND a.name LIKE '%Smith%' 
ORDER BY 
    t.production_year DESC, 
    p.name ASC 
LIMIT 100;
