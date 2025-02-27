SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    p.name AS person_name, 
    kt.kind AS kind_type
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Some Info Type')
ORDER BY 
    t.production_year DESC;
