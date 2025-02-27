SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_type,
    m.name AS company_name,
    i.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
WHERE 
    i.info IS NOT NULL
ORDER BY 
    t.production_year DESC, a.name;
