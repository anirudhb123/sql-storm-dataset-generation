SELECT 
    ak.name AS aka_name, 
    t.title AS movie_title, 
    c.role_id AS cast_role, 
    cn.name AS company_name, 
    k.keyword AS movie_keyword, 
    pi.info AS person_info, 
    ct.kind AS company_type
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info pi ON ak.person_id = pi.person_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    t.production_year >= 2000 
    AND k.keyword ILIKE '%action%'
ORDER BY 
    t.production_year DESC, ak.name, t.title;
