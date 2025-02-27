SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    ct.kind AS cast_type,
    ci.note AS character_note,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    comp_cast_type ct ON c.person_role_id = ct.id
LEFT JOIN 
    complete_cast cc ON cc.movie_id = t.id
LEFT JOIN 
    movie_info m ON m.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name ILIKE '%Smith%'
AND 
    t.production_year BETWEEN 2000 AND 2020
ORDER BY 
    t.production_year DESC, actor_name;
