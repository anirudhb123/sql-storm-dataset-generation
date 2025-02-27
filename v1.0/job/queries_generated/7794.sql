SELECT 
    t.title AS movie_title,
    p.name AS person_name,
    r.role AS person_role,
    c.info AS company_info,
    mk.keyword AS movie_keyword
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND c.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    p.name ASC;
