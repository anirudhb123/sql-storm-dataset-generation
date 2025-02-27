SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    t.id AS title_id,
    t.title AS movie_title,
    t.production_year,
    c.id AS cast_id,
    c.nr_order,
    r.role AS role_name,
    co.name AS company_name,
    co.country_code,
    m.info AS movie_info
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
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year > 2000 
    AND co.country_code = 'USA' 
    AND m.note IS NULL
ORDER BY 
    t.production_year DESC, 
    a.name ASC,
    c.nr_order ASC;
