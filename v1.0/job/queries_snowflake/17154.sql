SELECT 
    t.title, 
    a.name AS actor_name, 
    p.info AS actor_info
FROM 
    title t
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
    AND t.production_year > 2000
ORDER BY 
    t.production_year DESC;
