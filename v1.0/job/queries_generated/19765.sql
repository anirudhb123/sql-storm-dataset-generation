SELECT 
    t.title, 
    a.name AS actor_name, 
    ci.nr_order 
FROM 
    title t 
JOIN 
    cast_info ci ON t.id = ci.movie_id 
JOIN 
    aka_name a ON ci.person_id = a.person_id 
WHERE 
    t.production_year = 2020 
ORDER BY 
    ci.nr_order;
