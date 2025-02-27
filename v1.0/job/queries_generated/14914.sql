SELECT 
    t.title AS movie_title, 
    n.name AS person_name, 
    r.role AS person_role, 
    c.note AS cast_note, 
    ci.kind AS company_kind, 
    mi.info AS movie_info 
FROM 
    title t
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name n ON c.person_id = n.person_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ci ON mc.company_type_id = ci.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    t.title, 
    n.name;
