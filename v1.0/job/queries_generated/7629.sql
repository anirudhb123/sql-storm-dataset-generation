SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    t.title AS movie_title,
    c.role_id AS cast_role,
    r.role AS role_description,
    co.name AS company_name,
    ct.kind AS company_type,
    m.production_year,
    k.keyword AS movie_keyword,
    pi.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info pi ON a.person_id = pi.person_id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND k.keyword IN ('Drama', 'Action')
ORDER BY 
    t.production_year DESC, a.name;
