SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS character_role, 
    mk.keyword AS movie_keyword, 
    cn.name AS company_name 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    aka_title t ON c.movie_id = t.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name cn ON mc.company_id = cn.id 
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
ORDER BY 
    a.name, 
    t.production_year DESC 
LIMIT 100;
