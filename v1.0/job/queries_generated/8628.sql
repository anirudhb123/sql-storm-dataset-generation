SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_type,
    mn.name AS company_name,
    mi.info AS movie_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name mn ON mc.company_id = mn.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000 
    AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
ORDER BY 
    t.production_year DESC, a.name;
