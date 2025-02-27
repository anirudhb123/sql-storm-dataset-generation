SELECT 
    t.title, 
    a.name AS actor_name, 
    c.kind AS role_type, 
    m.production_year, 
    g.keyword 
FROM 
    title t 
JOIN 
    cast_info c ON t.id = c.movie_id 
JOIN 
    aka_name a ON c.person_id = a.person_id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword g ON mk.keyword_id = g.id 
JOIN 
    movie_info m ON t.id = m.movie_id 
WHERE 
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary')
ORDER BY 
    m.production_year DESC, 
    t.title;
