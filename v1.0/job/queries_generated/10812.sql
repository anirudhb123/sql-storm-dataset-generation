SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    r.role AS role_name, 
    c.company_name AS production_company
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
    role_type r ON cc.role_id = r.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    t.title;
