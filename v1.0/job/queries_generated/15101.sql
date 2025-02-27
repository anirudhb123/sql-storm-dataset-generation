SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS cast_note,
    m.production_year,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    title m ON t.movie_id = m.id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC;
