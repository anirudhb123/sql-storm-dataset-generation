SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_type,
    p.info AS person_info,
    m.info AS movie_info
FROM 
    aka_title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    info_type it ON p.info_type_id = it.id
JOIN 
    comp_cast_type ct ON ci.person_role_id = ct.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND cn.country_code = 'USA'
    AND it.info = 'Biography'
ORDER BY 
    t.title, a.name;
