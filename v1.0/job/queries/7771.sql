SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    co.name AS company_name,
    r.role AS role_name,
    mi.info AS movie_info
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON mi.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND co.country_code = 'USA'
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Budget')
ORDER BY 
    a.name, t.production_year DESC;
