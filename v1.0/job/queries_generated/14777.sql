SELECT 
    t.title, 
    a.name AS actor_name, 
    c.kind AS role, 
    cc.status_id, 
    m.info 
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
    role_type c ON ci.role_id = c.id 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    movie_info m ON t.id = m.movie_id 
WHERE 
    t.production_year >= 2000 
    AND cn.country_code = 'USA' 
ORDER BY 
    t.production_year DESC, 
    a.name;
