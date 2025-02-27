SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    co.name AS company_name, 
    cct.kind AS company_type, 
    mt.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type cct ON mc.company_type_id = cct.id
JOIN 
    movie_info mt ON t.id = mt.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND cct.kind LIKE '%Production%'
ORDER BY 
    t.production_year DESC, 
    a.name, 
    t.title;
