SELECT 
    t.title, 
    a.name AS actor_name, 
    p.info AS actor_info 
FROM 
    title t 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    aka_name a ON mc.company_id = a.person_id 
JOIN 
    cast_info c ON t.id = c.movie_id 
JOIN 
    person_info p ON c.person_id = p.person_id 
WHERE 
    t.production_year > 2000 
ORDER BY 
    t.title;
