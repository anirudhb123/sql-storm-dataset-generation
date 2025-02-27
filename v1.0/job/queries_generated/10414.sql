SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    c.kind AS comp_cast,
    k.keyword AS movie_keyword
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    company_name AS c ON cc.subject_id = c.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
