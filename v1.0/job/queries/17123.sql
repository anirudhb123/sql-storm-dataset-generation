SELECT 
    t.title, 
    a.name AS actor_name, 
    c.note AS character_name 
FROM 
    aka_title AS t 
JOIN 
    cast_info AS c ON t.id = c.movie_id 
JOIN 
    aka_name AS a ON c.person_id = a.person_id 
WHERE 
    t.production_year = 2023 
ORDER BY 
    t.title;
