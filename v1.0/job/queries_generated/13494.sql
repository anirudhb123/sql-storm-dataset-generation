SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role,
    m.production_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    kind_type k ON t.kind_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    k.kind = 'feature'
    AND m.production_year BETWEEN 1990 AND 2000
ORDER BY 
    m.production_year DESC;
