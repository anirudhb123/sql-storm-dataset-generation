SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    m.info AS movie_info,
    k.keyword AS movie_keyword,
    cp.name AS company_name,
    pt.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cp ON mc.company_id = cp.id
JOIN 
    person_info pt ON a.person_id = pt.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary')
    AND cp.country_code = 'USA'
ORDER BY 
    t.production_year DESC, a.name;
