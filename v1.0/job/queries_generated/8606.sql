SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    p.info AS person_info,
    kt.keyword AS movie_keyword,
    ct.kind AS company_type,
    ci.kind AS comp_cast_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    comp_cast_type ci ON c.person_role_id = ci.id
WHERE 
    t.production_year >= 2000
    AND ci.kind = 'Actor'
ORDER BY 
    t.production_year DESC, 
    a.name;
