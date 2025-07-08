SELECT 
    t.title, 
    p.name AS person_name, 
    r.role
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    role_type r ON ci.person_role_id = r.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.title;
