SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.nr_order AS cast_order, 
    p.info AS person_info, 
    cn.name AS company_name,
    ct.kind AS company_type,
    mt.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_info mt ON t.id = mt.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND (p.info_type_id IN (SELECT id FROM info_type WHERE info = 'birthdate') 
         OR mt.info_type_id IN (SELECT id FROM info_type WHERE info = 'summary'))
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
