SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    r.role AS role_type,
    mi.info AS movie_info
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
    role_type r ON ci.role_id = r.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year > 2000 
    AND a.name IS NOT NULL
    AND c.kind IS NOT NULL
ORDER BY 
    t.production_year DESC, 
    a.name ASC
LIMIT 100;
