SELECT 
    n.name AS actor_name, 
    t.title AS movie_title, 
    c.nr_order AS cast_order, 
    co.name AS company_name, 
    ct.kind AS company_type, 
    mi.info AS movie_info 
FROM 
    aka_name an 
JOIN 
    cast_info c ON an.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name co ON mc.company_id = co.id 
JOIN 
    company_type ct ON mc.company_type_id = ct.id 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
WHERE 
    an.name LIKE 'Robert%' 
    AND t.production_year >= 2000 
    AND ct.kind = 'Production' 
ORDER BY 
    t.production_year DESC, 
    c.nr_order ASC;
