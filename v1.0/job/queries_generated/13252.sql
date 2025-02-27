SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS actor_role,
    c.note AS cast_note,
    m.prod_year AS production_year
FROM 
    title AS t
JOIN 
    aka_title AS at ON t.id = at.movie_id
JOIN 
    cast_info AS c ON at.id = c.movie_id
JOIN 
    aka_name AS a ON c.person_id = a.person_id
JOIN 
    role_type AS r ON c.role_id = r.id
JOIN 
    movie_info AS m ON t.id = m.movie_id
WHERE 
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'release date')
ORDER BY 
    m.prod_year DESC;
