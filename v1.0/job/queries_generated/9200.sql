SELECT 
    ak.name AS aka_name, 
    t.title AS movie_title, 
    p.name AS person_name, 
    c.type AS company_type 
FROM 
    aka_name ak 
JOIN 
    cast_info ci ON ak.person_id = ci.person_id 
JOIN 
    title t ON ci.movie_id = t.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name cn ON mc.company_id = cn.id 
JOIN 
    company_type c ON mc.company_type_id = c.id 
JOIN 
    person_info pi ON ak.person_id = pi.person_id 
WHERE 
    t.production_year > 2000 
    AND c.kind = 'Production' 
    AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Bio') 
ORDER BY 
    t.production_year DESC, ak.name;
