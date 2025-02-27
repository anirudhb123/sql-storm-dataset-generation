SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS role_order,
    r.role AS role_type,
    y.production_year AS production_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    aka_title y ON t.id = y.movie_id
WHERE 
    y.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
ORDER BY 
    y.production_year DESC, 
    a.name;
