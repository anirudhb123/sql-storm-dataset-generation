SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS comp_cast_type,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_title AS t
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    comp_cast_type AS c ON ci.person_role_id = c.id
JOIN 
    movie_info AS m ON t.id = m.movie_id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, t.title;
