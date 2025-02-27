SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS role_order,
    r.role AS role_name,
    y.production_year
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    aka_title y ON t.id = y.movie_id
WHERE 
    y.kind_id = 1 -- Example condition for a specific kind of title
ORDER BY 
    a.name, y.production_year;
