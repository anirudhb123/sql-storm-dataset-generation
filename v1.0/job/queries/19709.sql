SELECT 
    t.title, 
    a.name AS actor_name, 
    ci.nr_order 
FROM 
    title t 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name c ON mc.company_id = c.id 
JOIN 
    cast_info ci ON t.id = ci.movie_id 
JOIN 
    aka_name a ON ci.person_id = a.person_id 
WHERE 
    c.country_code = 'USA' 
ORDER BY 
    t.production_year DESC, 
    ci.nr_order;
