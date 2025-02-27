SELECT 
    t.title, 
    a.name, 
    p.info 
FROM 
    title t 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
JOIN 
    person_info p ON mi.id = p.info_type_id 
JOIN 
    cast_info c ON t.id = c.movie_id 
JOIN 
    aka_name a ON c.person_id = a.person_id 
WHERE 
    t.production_year > 2000 
ORDER BY 
    t.title;
