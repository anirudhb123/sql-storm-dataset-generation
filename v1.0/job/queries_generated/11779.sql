SELECT 
    t.title AS movie_title,
    p.name AS person_name,
    c.note AS cast_note,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name p ON c.person_id = p.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.title, p.name;
