SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    r.role AS role_type,
    m.production_year AS year_produced
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
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    r.role LIKE 'Actor%'
AND 
    m.production_year BETWEEN 2000 AND 2023
ORDER BY 
    m.production_year DESC, 
    c.nr_order ASC;
