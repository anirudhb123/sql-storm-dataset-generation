SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order,
    r.role AS person_role,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    m.production_year
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000 
    AND r.role LIKE 'Actor%'
    AND co.country_code IS NOT NULL
ORDER BY 
    t.production_year DESC, 
    a.name, 
    r.role, 
    t.title;
