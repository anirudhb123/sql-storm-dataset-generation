SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    pn.name AS person_name,
    kt.keyword AS movie_keyword,
    ci.kind AS company_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    company_name cn ON t.id IN (SELECT movie_id FROM movie_companies WHERE company_id = cn.id)
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
JOIN 
    comp_cast_type ci ON c.role_id = ci.id
JOIN 
    name pn ON a.person_id = pn.imdb_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
