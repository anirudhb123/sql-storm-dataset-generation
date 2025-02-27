SELECT 
    t.title, 
    a.name AS actor_name, 
    c.kind AS cast_type, 
    r.role AS role_type, 
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
JOIN 
    kind_type k ON t.kind_id = k.id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year, t.title;
