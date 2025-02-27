SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS company_type,
    m.info AS movie_information,
    k.keyword AS movie_keyword,
    ct.role AS person_role
FROM 
    title AS t
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    cast_info AS ci ON cc.subject_id = ci.id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    company_type AS c ON mc.company_type_id = c.id
JOIN 
    movie_info AS m ON t.id = m.movie_id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    role_type AS ct ON ci.role_id = ct.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND a.name ILIKE '%Smith%'
    AND cn.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    a.name ASC
LIMIT 100;
