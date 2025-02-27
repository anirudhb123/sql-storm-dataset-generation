SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS character_order,
    ct.kind AS cast_type,
    p.info AS person_info,
    ci.company_name AS production_company,
    k.keyword AS movie_keyword,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name ci ON mc.company_id = ci.id
JOIN 
    keyword k ON t.id = k.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    comp_cast_type ct ON c.person_role_id = ct.id
WHERE 
    t.production_year >= 2000 
    AND ci.country_code = 'USA'
    AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Bio')
ORDER BY 
    t.production_year DESC, a.name ASC;
