SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS character_note,
    ci.note AS cast_info_note,
    p.info AS person_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON a.person_id = p.person_id
ORDER BY 
    t.production_year DESC;
