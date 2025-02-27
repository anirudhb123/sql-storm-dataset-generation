SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ci.nr_order AS cast_order
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.title, ci.nr_order;
