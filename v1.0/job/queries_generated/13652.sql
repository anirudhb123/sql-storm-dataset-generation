SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS actor_role,
    c.production_year,
    c.note AS movie_note
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    aka_name a ON cc.subject_id = a.person_id
JOIN 
    role_type r ON cc.role_id = r.id
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON a.id = ci.person_id AND t.id = ci.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    c.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
