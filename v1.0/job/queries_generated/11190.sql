SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS actor_role,
    c.kind AS company_type,
    m.info AS movie_info
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    aka_name a ON cc.subject_id = a.person_id
JOIN 
    role_type r ON cc.person_role_id = r.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year, t.title;
