SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    n.name AS person_name,
    r.role AS role_description,
    co.name AS company_name,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    name n ON a.person_id = n.imdb_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
AND 
    c.nr_order < 10
ORDER BY 
    t.production_year DESC, a.name;
