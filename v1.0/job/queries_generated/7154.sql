SELECT 
    t.title AS movie_title,
    c.name AS person_name,
    rt.role AS role_name,
    ci.note AS cast_note,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    mi.info AS movie_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
AND 
    k.keyword IS NOT NULL
AND 
    co.country_code = 'USA'
ORDER BY 
    t.production_year DESC, t.title ASC;
