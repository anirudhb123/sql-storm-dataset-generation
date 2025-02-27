SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    ci.nr_order AS cast_order,
    r.role AS role_type,
    c.name AS company_name,
    mi.info AS movie_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    ak.name IS NOT NULL
    AND t.production_year BETWEEN 2000 AND 2020
    AND c.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    ak.name;
