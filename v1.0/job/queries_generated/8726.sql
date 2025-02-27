SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.nr_order AS cast_order, 
    co.name AS company_name, 
    ki.keyword AS movie_keyword 
FROM 
    cast_info c 
JOIN 
    aka_name a ON c.person_id = a.person_id 
JOIN 
    aka_title t ON c.movie_id = t.movie_id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name co ON mc.company_id = co.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword ki ON mk.keyword_id = ki.id 
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
    AND a.name IS NOT NULL 
    AND co.country_code IN ('USA', 'UK') 
ORDER BY 
    t.production_year DESC, 
    c.nr_order ASC 
LIMIT 100;
