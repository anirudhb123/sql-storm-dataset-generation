SELECT 
    t.title, 
    a.name AS actor_name, 
    ci.note AS role_note
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
WHERE 
    t.production_year = 2023
ORDER BY 
    t.title;
