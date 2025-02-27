SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    c.kind AS character_type,
    c.nr_order AS role_order,
    co.name AS company_name,
    mc.note AS company_note,
    mi.info AS movie_info
FROM 
    aka_title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND a.name IS NOT NULL 
    AND co.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
