SELECT 
    p.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    co.name AS company_name,
    mi.info AS movie_info
FROM 
    aka_name p
JOIN 
    cast_info ci ON p.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id 
WHERE 
    p.name LIKE '%Smith%'
    AND t.production_year > 2000
    AND ci.nr_order < 3
ORDER BY 
    t.production_year DESC, 
    actor_name ASC;
