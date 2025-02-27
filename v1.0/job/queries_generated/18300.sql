SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.movie_id
JOIN 
    title t ON at.id = t.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
