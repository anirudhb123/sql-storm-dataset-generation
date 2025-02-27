SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.role_id,
    c.nr_order,
    ci.kind AS company_type,
    k.keyword AS movie_keyword,
    m.production_year,
    pi.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    keyword k ON t.id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'some_info_type')
    AND k.keyword = 'some_keyword'
ORDER BY 
    m.production_year DESC;
