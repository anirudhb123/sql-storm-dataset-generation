SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    k.keyword AS movie_keyword,
    p.info AS person_info,
    comp.name AS company_name
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name comp ON mc.company_id = comp.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000 
    AND k.keyword IS NOT NULL 
    AND a.name LIKE 'A%'
ORDER BY 
    t.production_year DESC, 
    a.name;
