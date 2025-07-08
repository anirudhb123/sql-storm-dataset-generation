SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    c.nr_order, 
    ci.kind, 
    m.name AS company_name, 
    k.keyword 
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    keyword k ON t.id = k.id
JOIN 
    comp_cast_type ci ON c.person_role_id = ci.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND ci.kind LIKE '%Actor%'
ORDER BY 
    t.production_year DESC, 
    a.name;
