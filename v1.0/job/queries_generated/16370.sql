SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword k ON t.id = k.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
