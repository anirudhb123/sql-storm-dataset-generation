SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    pi.info AS person_info,
    ct.kind AS company_type
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
