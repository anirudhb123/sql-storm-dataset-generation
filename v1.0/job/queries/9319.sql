SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    p.info AS actor_info 
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    title t ON ci.movie_id = t.id 
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id 
JOIN 
    person_info p ON a.person_id = p.person_id 
WHERE 
    t.production_year > 2000 
    AND c.kind = 'actor' 
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info IN ('birth date', 'birth place')) 
ORDER BY 
    t.production_year DESC, 
    a.name ASC 
LIMIT 100;
