SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    pt.info AS person_info,
    k.keyword AS movie_keyword,
    c.kind AS company_type
FROM 
    aka_title AS t
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    movie_info AS mi ON t.id = mi.movie_id
JOIN 
    person_info AS pt ON a.person_id = pt.person_id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_type AS c ON mc.company_type_id = c.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
