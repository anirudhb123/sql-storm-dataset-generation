SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    t.id AS title_id,
    t.title AS movie_title,
    c.id AS cast_id,
    n.name AS person_name,
    r.role AS role_type,
    m.id AS movie_company_id,
    co.name AS company_name
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies m ON t.id = m.movie_id
JOIN 
    company_name co ON m.company_id = co.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    name n ON a.person_id = n.imdb_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
