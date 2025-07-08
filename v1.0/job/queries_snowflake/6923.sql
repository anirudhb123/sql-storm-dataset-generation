SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    c.nr_order, 
    com.name AS company_name, 
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name com ON mc.company_id = com.id
JOIN 
    movie_keyword mw ON t.id = mw.movie_id
JOIN 
    keyword k ON mw.keyword_id = k.id
WHERE 
    t.production_year >= 2000
AND 
    com.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    a.name;
