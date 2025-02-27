SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role,
    p.info AS person_info,
    k.keyword AS movie_keyword
FROM 
    aka_title AS t
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    cast_info AS ci ON cc.subject_id = ci.id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    role_type AS c ON ci.role_id = c.id
LEFT JOIN 
    person_info AS p ON a.person_id = p.person_id
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND cn.country_code = 'USA'
    AND k.keyword IS NOT NULL
ORDER BY 
    t.title, a.name;
