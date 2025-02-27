SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.person_role_id,
    ci.kind,
    m.name AS company_name
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    comp_cast_type ci ON c.person_role_id = ci.id
WHERE 
    t.production_year = 2023
ORDER BY 
    ak.name, t.title;
