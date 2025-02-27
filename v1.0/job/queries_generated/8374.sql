SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    r.role AS role_type,
    ci.name AS company_name,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name ci ON mc.company_id = ci.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
  AND 
    ci.country_code = 'USA'
  AND 
    r.role IN (SELECT role FROM role_type WHERE role LIKE '%actor%')
ORDER BY 
    t.production_year DESC, 
    c.nr_order;
