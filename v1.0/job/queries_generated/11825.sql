SELECT 
    a.name AS alias_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    r.role AS role_name,
    m.production_year AS year_of_release,
    co.name AS company_name
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, 
    c.nr_order;
