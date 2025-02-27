SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id AS role_identification,
    co.name AS company_name,
    ki.keyword AS movie_keyword 
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
    keyword ki ON mk.keyword_id = ki.id 
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
    AND co.country_code = 'USA' 
ORDER BY 
    t.production_year DESC, 
    a.name;
