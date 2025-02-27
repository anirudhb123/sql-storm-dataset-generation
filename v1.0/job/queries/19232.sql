SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    ci.note AS cast_note,
    c.name AS company_name
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
WHERE 
    ci.nr_order = 1
AND 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
