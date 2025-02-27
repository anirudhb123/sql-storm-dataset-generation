SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order,
    r.role AS person_role,
    cn.name AS company_name,
    k.keyword AS keyword
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
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND cn.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    a.name, 
    k.keyword
LIMIT 100;
