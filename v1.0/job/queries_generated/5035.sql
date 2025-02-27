SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    c.nr_order AS cast_order, 
    co.name AS company_name,
    r.role AS role_type,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year >= 2000 
    AND co.country_code = 'USA'
    AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
ORDER BY 
    t.production_year DESC, 
    c.nr_order;
