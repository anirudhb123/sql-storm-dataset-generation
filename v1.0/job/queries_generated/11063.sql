SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS actor_name,
    ct.kind AS company_type,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ca ON a.person_id = ca.person_id
JOIN 
    title t ON ca.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
ORDER BY 
    t.production_year DESC;
