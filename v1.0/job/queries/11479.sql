SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    c.nr_order AS cast_order,
    r.role AS role_type,
    y.production_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title m ON c.movie_id = m.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    aka_title y ON m.id = y.movie_id
WHERE 
    y.production_year >= 2000
ORDER BY 
    y.production_year DESC, 
    a.name;
