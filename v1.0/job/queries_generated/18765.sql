SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    y.production_year
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
JOIN 
    title y ON m.id = y.id
WHERE 
    y.production_year > 2000
ORDER BY 
    y.production_year DESC;
