SELECT 
    t.title, 
    ak.name AS aka_name, 
    p.name AS person_name, 
    c.kind AS company_type, 
    m.info AS movie_info
FROM 
    title t
JOIN 
    aka_title ak ON t.id = ak.movie_id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    name p ON ci.person_id = p.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.title ASC, 
    ak.name ASC;
