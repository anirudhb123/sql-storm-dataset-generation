SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    r.role AS actor_role, 
    c.note AS cast_note, 
    tc.kind AS company_type,
    ci.name AS company_name,
    mi.info AS movie_info
FROM 
    title AS t
JOIN 
    cast_info AS c ON t.id = c.movie_id
JOIN 
    aka_name AS a ON c.person_id = a.person_id
JOIN 
    role_type AS r ON c.role_id = r.id
LEFT JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name AS ci ON mc.company_id = ci.id
LEFT JOIN 
    company_type AS ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_info AS mi ON t.id = mi.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND ct.kind = 'Distributor' 
    AND a.name IS NOT NULL 
ORDER BY 
    t.production_year DESC, a.name;
