-- Performance Benchmarking SQL Query
SELECT 
    t.title AS movie_title,
    p.name AS person_name,
    r.role AS role_name,
    c.note AS cast_note,
    c.nr_order AS cast_order,
    m.production_year AS movie_year,
    k.keyword AS movie_keyword
FROM 
    title AS t
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    cast_info AS c ON cc.subject_id = c.id
JOIN 
    aka_name AS p ON c.person_id = p.person_id
JOIN 
    role_type AS r ON c.role_id = r.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    p.name;
