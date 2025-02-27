SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.id AS cast_id,
    ci.kind AS cast_type,
    p.info AS person_info,
    k.keyword AS movie_keyword
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    title AS t ON c.movie_id = t.id
JOIN 
    comp_cast_type AS ci ON c.person_role_id = ci.id
JOIN 
    person_info AS p ON c.person_id = p.person_id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
