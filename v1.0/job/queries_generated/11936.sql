SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.role_id,
    co.name AS company_name,
    mt.kind AS company_type,
    m.production_year,
    p.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON t.id = c.movie_id
JOIN 
    movie_companies mc ON mc.movie_id = c.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
JOIN 
    title m ON m.id = c.movie_id
LEFT JOIN 
    person_info p ON p.person_id = a.person_id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, 
    a.name, 
    t.title;
