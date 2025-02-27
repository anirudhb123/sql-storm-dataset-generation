SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    cn.name AS company_name,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info mi ON mi.movie_id = t.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year > 2000
ORDER BY 
    t.production_year DESC;
