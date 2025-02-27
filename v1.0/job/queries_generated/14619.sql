SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    t.id AS title_id,
    t.title AS title,
    c.person_id AS cast_person_id,
    n.name AS person_name,
    r.role AS role_type,
    m.production_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    name n ON c.person_id = n.imdb_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    m.production_year > 2000
ORDER BY 
    m.production_year DESC,
    a.name;
