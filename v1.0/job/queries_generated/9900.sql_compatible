
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS role_order,
    r.role AS role_name,
    t.production_year,
    co.name AS company_name,
    k.keyword AS movie_keyword
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    complete_cast cc ON cc.movie_id = t.id AND cc.subject_id = c.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    aka_title at ON t.id = at.movie_id
WHERE 
    t.production_year >= 2000
GROUP BY 
    a.name, 
    t.title, 
    c.nr_order, 
    r.role, 
    t.production_year, 
    co.name, 
    k.keyword
ORDER BY 
    a.name, t.production_year DESC;
