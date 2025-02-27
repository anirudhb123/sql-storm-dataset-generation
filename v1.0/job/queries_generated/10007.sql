SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.person_role_id,
    c.nr_order,
    comp.name AS company_name,
    kw.keyword AS movie_keyword,
    info.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON mc.movie_id = t.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
LEFT JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON t.movie_id = mi.movie_id
LEFT JOIN 
    info_type info ON mi.info_type_id = info.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
