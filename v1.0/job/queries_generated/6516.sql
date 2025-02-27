SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    co.name AS company_name, 
    mi.info AS movie_info, 
    k.keyword AS movie_keyword 
FROM 
    aka_name AS a 
JOIN 
    cast_info AS c ON a.person_id = c.person_id 
JOIN 
    aka_title AS t ON c.movie_id = t.movie_id 
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id 
JOIN 
    company_name AS co ON mc.company_id = co.id 
JOIN 
    movie_info AS mi ON t.id = mi.movie_id 
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id 
JOIN 
    keyword AS k ON mk.keyword_id = k.id 
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
    AND co.country_code = 'USA' 
    AND c.nr_order < 5 
ORDER BY 
    actor_name, movie_title;
