SELECT 
    t.title AS movie_title,
    p.name AS person_name,
    c.nr_order AS role_order,
    rt.role AS person_role,
    c.note AS role_note,
    m.production_year
FROM 
    aka_title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name p ON c.person_id = p.person_id
JOIN 
    role_type rt ON c.role_id = rt.id
JOIN 
    title m ON t.id = m.id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, 
    t.title;
