SELECT 
    t.title,
    a.name AS actor_name,
    c.kind AS cast_type,
    k.keyword AS movie_keyword,
    m.info AS movie_info
FROM 
    aka_name AS a 
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
JOIN 
    comp_cast_type AS c ON ci.person_role_id = c.id
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info AS m ON t.id = m.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
