SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    p.info AS person_info,
    kt.keyword AS movie_keyword,
    cp.kind AS company_type,
    i.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id
LEFT JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
LEFT JOIN 
    company_type cp ON mc.company_type_id = cp.id
LEFT JOIN 
    movie_info i ON t.movie_id = i.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name, c.nr_order;
