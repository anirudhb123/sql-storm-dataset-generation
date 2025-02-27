SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS actor_role,
    m.production_year,
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
    akap_name a ON cc.subject_id = a.id
JOIN 
    cast_info ci ON a.person_id = ci.person_id AND ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
ORDER BY 
    m.production_year DESC, t.title ASC;
