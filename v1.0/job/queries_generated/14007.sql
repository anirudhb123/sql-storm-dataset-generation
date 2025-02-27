SELECT 
    t.title, 
    a.name AS actor_name, 
    ci.note AS role_note, 
    c.name AS company_name,
    m.year AS production_year
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
