SELECT 
    t.title AS movie_title,
    p.name AS person_name,
    r.role AS role_type,
    c.name AS company_name,
    k.keyword AS keyword,
    m.info AS movie_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
AND 
    c.country_code = 'USA'
AND 
    m.info_type_id IN (SELECT id FROM info_type WHERE info = 'budget')
ORDER BY 
    t.production_year DESC, p.name;
