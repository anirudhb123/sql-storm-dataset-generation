SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    pc.kind AS role,
    c.name AS company_name,
    mi.info AS movie_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type pc ON ci.role_id = pc.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
    AND c.country_code = 'USA'
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Award')
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
