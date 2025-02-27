SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
WHERE 
    t.kind_id = 1; -- Assuming 1 corresponds to a certain kind of title, e.g., 'movie'
