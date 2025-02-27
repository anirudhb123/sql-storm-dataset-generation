SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    r.role AS role_type,
    ci.name AS company_name,
    ci.country_code AS company_country,
    k.keyword AS movie_keyword,
    mt.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name ci ON mc.company_id = ci.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mt ON t.id = mt.movie_id
WHERE 
    t.production_year >= 2000
    AND ci.country_code IN ('USA', 'UK')
ORDER BY 
    t.production_year DESC, a.name, c.nr_order;
