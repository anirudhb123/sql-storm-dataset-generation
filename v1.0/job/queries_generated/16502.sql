SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS character_name,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    char_name c ON c.imdb_id = ci.person_role_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
