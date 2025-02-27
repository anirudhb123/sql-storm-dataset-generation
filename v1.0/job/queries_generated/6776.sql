SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_type,
    comp.name AS company_name,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year > 2000 
    AND a.name IS NOT NULL 
    AND comp.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    a.name ASC
LIMIT 100;
