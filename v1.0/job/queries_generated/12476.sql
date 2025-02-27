SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    r.role AS role_name,
    c.note AS cast_note,
    m.year AS production_year,
    k.keyword AS movie_keyword
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    title AS t ON c.movie_id = t.id
JOIN 
    name AS p ON c.person_id = p.imdb_id
JOIN 
    role_type AS r ON c.role_id = r.id
JOIN 
    movie_info AS m ON t.id = m.movie_id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
