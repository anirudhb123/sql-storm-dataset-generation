SELECT 
    t.title,
    a.name AS actor_name,
    c.kind AS cast_type,
    k.keyword AS movie_keyword,
    p.info AS person_info
FROM 
    title AS t
JOIN 
    movie_info AS mi ON t.id = mi.movie_id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    cast_info AS ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    comp_cast_type AS c ON ci.role_id = c.id
JOIN 
    person_info AS p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
