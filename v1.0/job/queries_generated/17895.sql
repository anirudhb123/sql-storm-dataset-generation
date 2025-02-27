SELECT 
    t.title, 
    a.name AS actor_name, 
    c.nr_order, 
    co.name AS company_name
FROM 
    title t
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.title, c.nr_order;
