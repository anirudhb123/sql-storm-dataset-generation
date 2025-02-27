SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    n.name AS person_name,
    kt.kind AS kind_type,
    co.name AS company_name,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name IS NOT NULL
    AND t.production_year > 2000
ORDER BY 
    t.production_year DESC;
