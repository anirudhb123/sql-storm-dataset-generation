SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    c.kind AS company_type,
    r.role AS role_type
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    name p ON a.person_id = p.imdb_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
