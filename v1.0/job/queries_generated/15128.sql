SELECT 
    t.title, 
    a.name AS actor_name, 
    c.kind AS role 
FROM 
    aka_title a 
JOIN 
    cast_info c ON a.id = c.movie_id 
JOIN 
    title t ON c.movie_id = t.id 
WHERE 
    t.production_year > 2000 
ORDER BY 
    t.production_year DESC;
