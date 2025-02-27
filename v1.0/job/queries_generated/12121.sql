SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    p.info AS actor_info, 
    c.kind AS company_type_str
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    aka_name a ON cc.subject_id = a.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
