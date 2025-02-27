SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.person_role_id,
    ci.kind,
    mn.name AS company_name,
    mt.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name mn ON mc.company_id = mn.id
JOIN 
    movie_info mt ON t.id = mt.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
