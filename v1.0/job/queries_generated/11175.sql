SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    ct.kind AS role_type,
    com.name AS company_name,
    mi.info AS movie_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    aka_title AS t ON c.movie_id = t.id
LEFT JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name AS com ON mc.company_id = com.id
LEFT JOIN 
    movie_info AS mi ON t.id = mi.movie_id
LEFT JOIN 
    role_type AS ct ON c.role_id = ct.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
ORDER BY 
    t.production_year, a.name;
