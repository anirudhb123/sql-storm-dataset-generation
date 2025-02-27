SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    c.kind AS company_type,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
ORDER BY 
    t.production_year DESC, a.name;
