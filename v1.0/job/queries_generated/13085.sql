SELECT 
    t.title AS movie_title,
    c.name AS person_name,
    r.role AS role_type,
    m.production_year,
    k.keyword AS movie_keyword
FROM 
    aka_title AS t
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    cast_info AS ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name AS c ON ci.person_id = c.person_id
JOIN 
    role_type AS r ON ci.role_id = r.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    movie_info AS mi ON t.id = mi.movie_id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'plot')
ORDER BY 
    m.production_year DESC;
