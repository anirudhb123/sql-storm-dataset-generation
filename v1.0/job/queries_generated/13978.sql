SELECT 
    a.id AS aka_name_id,
    a.name AS aka_name,
    t.id AS title_id,
    t.title AS movie_title,
    c.person_id AS cast_person_id,
    c.movie_id AS cast_movie_id,
    p.id AS person_info_id,
    p.info AS person_info,
    m.id AS movie_info_id,
    m.info AS movie_info,
    k.keyword AS movie_keyword,
    ln.link AS movie_link_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_link ml ON t.id = ml.movie_id
LEFT JOIN 
    link_type ln ON ml.link_type_id = ln.id
ORDER BY 
    t.production_year DESC, 
    a.name;
