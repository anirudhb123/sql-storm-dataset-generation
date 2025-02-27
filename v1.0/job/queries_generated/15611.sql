SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    cc.kind AS company_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type cc ON mc.company_type_id = cc.id
WHERE 
    a.name IS NOT NULL
ORDER BY 
    t.production_year DESC;
