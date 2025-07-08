SELECT 
    p.name AS person_name,
    m.title AS movie_title,
    c.nr_order AS cast_order,
    r.role AS role_name,
    t.production_year
FROM 
    cast_info c
JOIN 
    aka_name p ON c.person_id = p.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    title t ON m.id = t.id
WHERE 
    t.production_year IS NOT NULL
ORDER BY 
    t.production_year, c.nr_order;
