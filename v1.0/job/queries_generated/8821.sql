SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    c.kind AS company_type, 
    k.keyword AS movie_keyword, 
    pi.info AS person_info
FROM 
    aka_title AS t
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    cast_info AS ci ON cc.subject_id = ci.id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_type AS c ON mc.company_type_id = c.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    person_info AS pi ON a.person_id = pi.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
AND 
    a.name IS NOT NULL
ORDER BY 
    t.title, a.name;
