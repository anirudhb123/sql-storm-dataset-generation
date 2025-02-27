SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS company_type, 
    i.info AS additional_info 
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    title t ON ci.movie_id = t.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_type c ON mc.company_type_id = c.id 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
JOIN 
    info_type i ON mi.info_type_id = i.id 
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND c.kind ILIKE '%film%' 
    AND i.info_type_id IN (SELECT id FROM info_type WHERE info ILIKE '%awards%') 
ORDER BY 
    t.production_year DESC, a.name ASC;
