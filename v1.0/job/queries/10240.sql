SELECT 
    t.title,
    a.name AS aka_name,
    c.name AS character_name,
    ci.note AS cast_note,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON ci.movie_id = t.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    char_name c ON ci.person_id = c.imdb_id
JOIN 
    movie_info m ON m.movie_id = t.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON k.id = mk.keyword_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, t.title;
