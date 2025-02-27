SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS cast_type,
    ct2.kind AS company_type,
    cn.name AS company_name,
    mi.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_title AS t
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    company_type AS ct2 ON mc.company_type_id = ct2.id
JOIN 
    movie_info AS mi ON t.id = mi.movie_id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    role_type AS ct ON ci.role_id = ct.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
