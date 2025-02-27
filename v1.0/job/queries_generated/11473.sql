SELECT 
    t.title AS movie_title,
    ka.name AS actor_name,
    c.kind AS company_kind,
    k.keyword AS movie_keyword,
    p.info AS person_info
FROM 
    aka_title AS t
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS ka ON ci.person_id = ka.person_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_type AS c ON mc.company_type_id = c.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    person_info AS p ON ka.person_id = p.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    t.title, 
    ka.name;
