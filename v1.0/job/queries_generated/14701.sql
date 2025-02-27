SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    c.role_id AS role,
    m.production_year,
    k.keyword AS keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    name p ON a.person_id = p.imdb_id
WHERE 
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'Description')
ORDER BY 
    m.production_year DESC;
