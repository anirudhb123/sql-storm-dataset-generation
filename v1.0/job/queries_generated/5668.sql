SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    cc.company_id, 
    co.name AS company_name, 
    c.nr_order AS actor_order
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
    comp_cast_type cc ON c.person_role_id = cc.id
WHERE 
    co.country_code = 'USA' AND 
    t.production_year > 2000 AND 
    c.nr_order < 5
ORDER BY 
    t.production_year DESC, a.name ASC;
