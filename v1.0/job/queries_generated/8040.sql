SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    ci.note AS cast_note, 
    m.info AS movie_info, 
    kc.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kc ON mk.keyword_id = kc.id
WHERE 
    t.production_year >= 2000 
    AND c.kind = 'actor'
ORDER BY 
    a.name, 
    t.title;
