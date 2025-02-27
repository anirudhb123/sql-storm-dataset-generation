SELECT 
    t.title, 
    a.name AS actor_name, 
    c.kind AS role, 
    m.production_year
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
