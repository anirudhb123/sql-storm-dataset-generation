SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_type,
    m.company_name AS production_company,
    k.keyword AS movie_keyword
FROM 
    aka_title AS t
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    cast_info AS ci ON cc.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS m ON mc.company_id = m.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    role_type AS c ON ci.role_id = c.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.title, a.name;
