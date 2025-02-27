SELECT 
    t.title,
    a.name AS actor_name,
    c.kind AS role_kind,
    m.name AS company_name,
    ti.info AS movie_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    movie_info ti ON t.id = ti.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
