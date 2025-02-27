SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year
FROM 
    aka_name a
INNER JOIN 
    cast_info c ON a.person_id = c.person_id
INNER JOIN 
    aka_title t ON c.movie_id = t.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
