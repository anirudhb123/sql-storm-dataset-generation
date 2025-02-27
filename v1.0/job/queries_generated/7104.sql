SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    p.info AS personal_info,
    m.info AS movie_info,
    k.keyword AS keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    kind_type k ON t.kind_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    info_type it ON m.info_type_id = it.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    t.production_year >= 2000
    AND it.info = 'Director'
    AND k.kind = 'Feature'
ORDER BY 
    t.production_year DESC, a.name;
