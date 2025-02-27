SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    ci.nr_order AS casting_order,
    c.name AS company_name,
    ki.keyword AS movie_keyword,
    mi.info AS movie_info,
    ct.kind AS company_type
FROM 
    aka_title AS t
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    cast_info AS ci ON cc.subject_id = ci.id
JOIN 
    aka_name AS ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS c ON mc.company_id = c.id
JOIN 
    company_type AS ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS ki ON mk.keyword_id = ki.id
LEFT JOIN 
    movie_info AS mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
WHERE 
    t.production_year > 2000
    AND ak.name IS NOT NULL
ORDER BY 
    t.production_year DESC, 
    ak.name, 
    ci.nr_order;
