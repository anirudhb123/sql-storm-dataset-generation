SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    p.gender AS actor_gender,
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
    person_info p ON c.person_id = p.person_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_info m ON t.id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Tagline')
WHERE 
    a.name LIKE '%Smith%'
    AND t.production_year BETWEEN 1990 AND 2020
ORDER BY 
    t.production_year DESC, c.nr_order ASC;
