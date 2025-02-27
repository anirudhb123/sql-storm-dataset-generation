SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    w.info AS movie_info,
    p.info AS person_info,
    c.kind AS company_type
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_info w ON t.id = w.movie_id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
WHERE 
    a.name LIKE '%Smith%'
    AND t.production_year BETWEEN 2000 AND 2023
ORDER BY 
    t.production_year DESC, 
    a.name;
