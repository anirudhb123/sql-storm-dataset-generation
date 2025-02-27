SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.note AS character_name 
FROM 
    cast_info c 
JOIN 
    aka_name a ON c.person_id = a.person_id 
JOIN 
    aka_title t ON c.movie_id = t.movie_id 
WHERE 
    a.name IS NOT NULL 
    AND t.title IS NOT NULL 
ORDER BY 
    a.name, t.title;
