SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_role,
    m.production_year,
    COUNT(*) AS role_count
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
    movie_info mi ON t.id = mi.movie_id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'plot')
GROUP BY 
    t.title, a.name, c.kind, m.production_year
ORDER BY 
    role_count DESC;
