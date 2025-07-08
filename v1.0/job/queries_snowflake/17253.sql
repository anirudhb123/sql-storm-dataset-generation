SELECT 
    t.title, 
    p.name, 
    c.nr_order, 
    r.role 
FROM 
    title t 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name cn ON mc.company_id = cn.id 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    cast_info c ON cc.subject_id = c.person_id 
JOIN 
    aka_name p ON c.person_id = p.person_id 
JOIN 
    role_type r ON c.role_id = r.id 
WHERE 
    t.production_year = 2020 
ORDER BY 
    t.title;
