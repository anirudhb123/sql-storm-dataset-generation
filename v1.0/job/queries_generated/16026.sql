SELECT 
    ak.name AS actor_name,
    ti.title AS movie_title,
    ti.production_year
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title ti ON ci.movie_id = ti.movie_id
WHERE 
    ti.production_year > 2000
ORDER BY 
    ti.production_year DESC;
