SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_kind, 
    r.role AS role_name, 
    m.info AS movie_info, 
    k.keyword AS movie_keyword, 
    comp.name AS company_name
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name comp ON mc.company_id = comp.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year BETWEEN 2000 AND 2022
    AND comp.country_code IN ('USA', 'UK', 'CAN')
ORDER BY 
    t.production_year DESC, 
    actor_name ASC;
