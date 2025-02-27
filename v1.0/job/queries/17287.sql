SELECT 
    t.title, 
    a.name AS actor_name, 
    c.nr_order 
FROM 
    title t 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    cast_info c ON cc.subject_id = c.id 
JOIN 
    aka_name a ON c.person_id = a.person_id 
WHERE 
    t.production_year > 2000 
ORDER BY 
    t.title, c.nr_order;
