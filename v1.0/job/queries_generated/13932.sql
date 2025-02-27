SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_type,
    ci.note AS cast_note,
    m.production_year
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type c ON ci.role_id = c.id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
    AND t.production_year BETWEEN 2000 AND 2020
ORDER BY 
    m.production_year DESC, t.title;
