SELECT 
    t.title,
    a.name AS actor_name,
    k.keyword AS movie_keyword,
    c.name AS company_name,
    ty.kind AS company_type,
    p.info AS person_info
FROM 
    aka_title AS t
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS c ON mc.company_id = c.id
JOIN 
    company_type AS ty ON mc.company_type_id = ty.id
JOIN 
    person_info AS p ON a.person_id = p.person_id
ORDER BY 
    t.production_year DESC, 
    t.title 
LIMIT 100;
