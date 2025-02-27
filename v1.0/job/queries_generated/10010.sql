SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    c.role_id AS role_id, 
    pi.info AS person_info, 
    ct.kind AS company_type
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    person_info pi ON a.person_id = pi.person_id
JOIN 
    comp_cast_type ct ON c.person_role_id = ct.id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'plot')
    AND t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
