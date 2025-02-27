SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.nr_order AS cast_order, 
    r.role AS role_type 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    role_type r ON c.role_id = r.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name co ON mc.company_id = co.id 
WHERE 
    r.role = 'Lead' 
    AND t.production_year BETWEEN 1990 AND 2000 
    AND co.country_code = 'USA' 
ORDER BY 
    t.production_year DESC, 
    a.name ASC 
LIMIT 100;
