SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    p.info AS person_info,
    kk.keyword AS movie_keyword,
    ct.kind AS company_type,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kk ON mk.keyword_id = kk.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    person_info p ON c.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND kk.keyword LIKE '%action%'
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%biography%')
ORDER BY 
    t.production_year DESC, c.nr_order;
