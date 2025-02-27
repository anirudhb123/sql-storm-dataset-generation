SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    c.kind AS role_type,
    m.year AS production_year
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
JOIN 
    role_type AS c ON ci.role_id = c.id
JOIN 
    movie_info AS m ON t.id = m.movie_id
WHERE 
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'release year')
ORDER BY 
    m.info DESC;
