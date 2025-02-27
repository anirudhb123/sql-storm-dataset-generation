SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    c.note AS cast_note
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
WHERE 
    m.production_year > 2000
ORDER BY 
    a.name, m.production_year;
