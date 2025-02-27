SELECT 
    t.title,
    m.production_year,
    p.name AS actor_name,
    r.role,
    c.kind AS company_type
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON at.movie_id = ci.movie_id
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Budget')
ORDER BY 
    m.production_year DESC, 
    t.title;
