SELECT 
    t.title AS movie_title,
    k.keyword AS movie_keyword,
    c.name AS company_name,
    p.info AS person_info,
    ak.name AS aka_name,
    r.role AS role_type
FROM 
    title t
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    person_info p ON ak.person_id = p.person_id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year >= 2000 
    AND mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Distributor')
ORDER BY 
    t.production_year ASC, 
    c.name ASC;
