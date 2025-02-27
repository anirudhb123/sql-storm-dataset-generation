SELECT 
    a.name AS alias_name,
    t.title AS movie_title,
    p.name AS person_name,
    r.role AS role,
    c.kind AS company_type,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
ORDER BY 
    a.name, t.production_year DESC;
