SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    co.name AS company_name,
    kt.keyword AS movie_keyword,
    mu.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
JOIN 
    movie_info mu ON t.id = mu.movie_id
WHERE 
    t.production_year > 2000
    AND a.name LIKE 'A%'
    AND mu.info_type_id IN (SELECT id FROM info_type WHERE info = 'Budget')
ORDER BY 
    t.production_year DESC, 
    a.name;
