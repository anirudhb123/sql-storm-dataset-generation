SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    c.kind AS role_type, 
    c.nr_order AS role_order, 
    p.info AS actor_info, 
    co.name AS company_name, 
    m.info AS movie_note 
FROM 
    title t 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    cast_info c ON cc.subject_id = c.id 
JOIN 
    aka_name a ON c.person_id = a.person_id 
LEFT JOIN 
    person_info p ON a.person_id = p.person_id 
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id 
LEFT JOIN 
    company_name co ON mc.company_id = co.id 
LEFT JOIN 
    movie_info m ON t.id = m.movie_id 
WHERE 
    t.production_year > 2000 
    AND c.nr_order < 5 
    AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography') 
ORDER BY 
    t.title ASC, 
    c.nr_order DESC;
