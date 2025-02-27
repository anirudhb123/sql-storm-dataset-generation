SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    r.role AS role_type,
    co.name AS company_name,
    ti.info AS movie_info
FROM 
    aka_name AS ak
JOIN 
    cast_info AS c ON ak.person_id = c.person_id
JOIN 
    title AS t ON c.movie_id = t.id
JOIN 
    role_type AS r ON c.role_id = r.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS co ON mc.company_id = co.id
JOIN 
    movie_info AS ti ON t.id = ti.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, c.nr_order;
