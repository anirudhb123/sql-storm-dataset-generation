SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    ci.note AS cast_note,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
JOIN 
    comp_cast_type AS c ON ci.person_role_id = c.id
JOIN 
    movie_info AS m ON t.id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    a.name LIKE '%Smith%'
    AND t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
