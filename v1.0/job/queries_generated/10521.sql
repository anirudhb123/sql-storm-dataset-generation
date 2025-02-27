SELECT 
    t.title,
    a.name AS actor_name,
    c.kind AS character_name,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    aka_title a_t ON t.id = a_t.movie_id
JOIN 
    cast_info ci ON a_t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    char_name c ON ci.role_id = c.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.title ASC;
