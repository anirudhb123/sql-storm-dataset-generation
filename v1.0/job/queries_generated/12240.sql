SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS actor_role,
    m.production_year
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
ORDER BY 
    m.production_year DESC, t.title;
