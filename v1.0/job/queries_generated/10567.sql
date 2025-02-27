SELECT 
    a.id AS aka_name_id,
    a.name AS aka_name,
    t.id AS title_id,
    t.title AS movie_title,
    c.id AS cast_info_id,
    n.name AS actor_name,
    pt.role AS role,
    m.production_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    name n ON a.person_id = n.imdb_id
JOIN 
    role_type pt ON c.role_id = pt.id
WHERE 
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
AND 
    m.info LIKE '%action%'
ORDER BY 
    m.production_year DESC;
