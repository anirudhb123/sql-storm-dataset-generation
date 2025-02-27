SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS role,
    tc.info AS title_comment
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type ct ON ci.role_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
