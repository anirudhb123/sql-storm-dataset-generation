SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    r.role AS role_name,
    co.name AS company_name,
    m.production_year AS year
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    title AS t ON c.movie_id = t.id
JOIN 
    role_type AS r ON c.role_id = r.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS co ON mc.company_id = co.id
JOIN 
    movie_info AS mi ON t.id = mi.movie_id
WHERE 
    mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
ORDER BY 
    m.production_year DESC, a.name;
