SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.role_id,
    p.info AS person_info,
    COALESCE(ca.kind, 'No role type') AS role_type,
    mc.company_id,
    co.name AS company_name,
    ci.country_code
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    person_info p ON ak.person_id = p.person_id
LEFT JOIN 
    role_type ca ON c.role_id = ca.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000 
    AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
ORDER BY 
    t.production_year DESC, ak.name;
