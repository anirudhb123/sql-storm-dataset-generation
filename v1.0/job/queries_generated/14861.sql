SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    ci.nr_order AS cast_order,
    c.name AS company_name,
    ti.info AS movie_info,
    kw.keyword AS movie_keyword
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    aka_title AS t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS c ON mc.company_id = c.id
JOIN 
    movie_info AS mi ON t.id = mi.movie_id
JOIN 
    info_type AS ti ON mi.info_type_id = ti.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS kw ON mk.keyword_id = kw.id
WHERE 
    mi.info_type_id IS NOT NULL
ORDER BY 
    t.production_year DESC, ci.nr_order;
