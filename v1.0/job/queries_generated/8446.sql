SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_type,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    m.info AS movie_information,
    cn.name AS company_name,
    ct.kind AS company_type
FROM 
    aka_title AS t
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    comp_cast_type AS c ON ci.person_role_id = c.id
JOIN 
    movie_info AS m ON t.id = m.movie_id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    company_type AS ct ON mc.company_type_id = ct.id
JOIN 
    person_info AS p ON a.id = p.person_id
WHERE 
    t.production_year >= 2000
    AND k.keyword LIKE '%action%'
ORDER BY 
    t.production_year DESC, a.name;
