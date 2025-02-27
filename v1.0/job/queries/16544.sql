SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year AS year_of_release 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    aka_title t ON c.movie_id = t.movie_id 
WHERE 
    a.name IS NOT NULL 
ORDER BY 
    t.production_year DESC;
