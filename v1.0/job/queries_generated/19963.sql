SELECT 
    t.title, 
    p.name AS actor_name, 
    c.note AS character_name
FROM 
    title t
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name p ON p.person_id = c.person_id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'tagline')
    AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Distributor')
ORDER BY 
    t.production_year DESC;
