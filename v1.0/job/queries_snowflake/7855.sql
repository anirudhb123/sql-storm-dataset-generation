SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    m.info AS movie_info,
    c.kind AS company_type,
    r.role AS role_name
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'box office' LIMIT 1)
ORDER BY 
    t.production_year DESC, a.name ASC
LIMIT 100;
