SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    ci.nr_order AS cast_order,
    c.name AS company_name,
    kt.keyword AS movie_keyword,
    mt.kind AS movie_type
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
JOIN 
    kind_type mt ON t.kind_id = mt.id
JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    mt.kind = 'Feature'
ORDER BY 
    t.production_year DESC, 
    ak.name;
