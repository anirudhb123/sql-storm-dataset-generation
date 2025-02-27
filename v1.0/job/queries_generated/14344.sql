SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    ci.nr_order AS cast_order,
    rn.role AS role_name,
    c.name AS company_name,
    ct.kind AS company_type,
    kw.keyword AS movie_keyword,
    mi.info AS movie_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
JOIN 
    role_type AS rn ON ci.role_id = rn.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS c ON mc.company_id = c.id
JOIN 
    company_type AS ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword AS kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info AS mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name, 
    ci.nr_order;
