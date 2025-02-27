SELECT 
    n.name AS actor_name,
    t.title AS movie_title,
    c.note AS cast_note,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    cast_info c
JOIN 
    aka_name n ON c.person_id = n.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    n.name IS NOT NULL
    AND t.title IS NOT NULL
    AND c.note IS NOT NULL
ORDER BY 
    actor_name, movie_title;
