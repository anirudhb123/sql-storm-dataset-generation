SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    mc.note AS company_note, 
    mi.info AS movie_info 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    aka_title t ON c.movie_id = t.movie_id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
WHERE 
    a.name LIKE 'A%' 
    AND t.production_year BETWEEN 2000 AND 2023 
    AND mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Production') 
ORDER BY 
    t.production_year DESC, a.name;
