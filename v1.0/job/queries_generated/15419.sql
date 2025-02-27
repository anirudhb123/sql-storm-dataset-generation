SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title m ON ci.movie_id = m.movie_id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC;
