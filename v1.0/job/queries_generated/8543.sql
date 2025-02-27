SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    ct.kind AS company_type,
    ki.keyword AS keyword,
    mi.info AS movie_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    ak.name IS NOT NULL
    AND t.production_year BETWEEN 2000 AND 2023
    AND cn.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    ak.name;
