SELECT 
    t.title, 
    p.name AS person_name, 
    ct.kind AS cast_type
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    comp_cast_type cct ON ci.person_role_id = cct.id
WHERE 
    t.production_year >= 2000
    AND cn.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    t.title;
