SELECT 
    t.title AS movie_title,
    c.name AS cast_name,
    r.role AS role_type,
    p.info AS person_info,
    co.name AS company_name,
    m.info AS movie_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    name n ON an.person_id = n.imdb_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    person_info p ON an.person_id = p.person_id
WHERE 
    t.production_year >= 2000
    AND co.country_code = 'USA'
    AND r.role = 'Actor'
ORDER BY 
    t.production_year DESC, 
    t.title ASC, 
    cast_name ASC;
