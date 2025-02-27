SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.role AS cast_role,
    co.name AS company_name,
    mi.info AS movie_info,
    k.keyword AS movie_keyword,
    p.info AS person_info
FROM 
    aka_name ak
JOIN 
    cast_info ca ON ak.person_id = ca.person_id
JOIN 
    title t ON ca.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON ak.person_id = p.person_id
WHERE 
    co.country_code = 'USA' 
    AND t.production_year BETWEEN 1990 AND 2020
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
ORDER BY 
    t.production_year DESC, ak.name, t.title;
