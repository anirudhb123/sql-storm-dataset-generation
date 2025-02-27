SELECT 
    a.name AS alias_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    co.name AS company_name,
    kt.keyword AS movie_keyword,
    p.info AS person_information
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year > 2000
    AND co.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    a.name, 
    c.nr_order;
