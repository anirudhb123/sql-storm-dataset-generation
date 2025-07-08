SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS character_name,
    y.production_year
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    title y ON t.id = y.id
WHERE 
    y.production_year > 2000
ORDER BY 
    y.production_year DESC;
