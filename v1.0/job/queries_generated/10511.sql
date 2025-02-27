SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.role_id AS role_id,
    cc.kind AS comp_cast_type,
    m.name AS company_name,
    mt.kind AS company_type,
    ti.info AS movie_info
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    t.production_year >= 2000
    AND m.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
