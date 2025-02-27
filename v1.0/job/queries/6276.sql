SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.role_id AS role_id, 
    co.name AS company_name, 
    k.keyword AS movie_keyword 
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
    keyword k ON mk.keyword_id = k.id 
WHERE 
    a.name LIKE 'A%' 
    AND t.production_year BETWEEN 2000 AND 2023 
    AND co.country_code = 'USA' 
ORDER BY 
    a.name, t.production_year DESC 
LIMIT 100;
