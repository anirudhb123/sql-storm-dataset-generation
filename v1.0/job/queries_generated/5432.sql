SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS cast_note,
    m.info AS movie_info,
    k.keyword AS movie_keyword,
    p.info AS person_info,
    cc.kind AS comp_cast_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    complete_cast cc ON cc.movie_id = t.id
WHERE 
    t.production_year > 2000 
    AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards')
    AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
ORDER BY 
    t.production_year DESC, 
    a.name;
