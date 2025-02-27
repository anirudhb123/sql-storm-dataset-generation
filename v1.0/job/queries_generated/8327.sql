SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    tc.kind AS company_type,
    c.note AS cast_note,
    i.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info i ON t.id = i.movie_id
WHERE 
    t.production_year > 2000
    AND ct.kind = 'Producer'
ORDER BY 
    t.production_year DESC, 
    a.name ASC
LIMIT 100;
