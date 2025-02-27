SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    t.title AS movie_title,
    t.production_year,
    c.nr_order,
    cc.kind AS cast_type,
    co.name AS company_name,
    ki.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
JOIN 
    comp_cast_type cc ON c.person_role_id = cc.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
AND 
    c.nr_order < 5
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
