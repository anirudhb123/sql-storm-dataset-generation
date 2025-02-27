SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    m.company_id AS production_company,
    k.keyword AS movie_keyword,
    r.role AS role_name
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies m ON t.id = m.movie_id
JOIN 
    company_name co ON m.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND co.country_code = 'USA'
    AND k.keyword IS NOT NULL
ORDER BY 
    t.production_year DESC, 
    a.name ASC, 
    c.nr_order ASC
LIMIT 100;
