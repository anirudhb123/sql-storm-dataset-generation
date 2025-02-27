SELECT 
    t.title,
    a.name AS actor_name,
    ci.role_id,
    c.kind AS company_type
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_type c ON mc.company_type_id = c.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
