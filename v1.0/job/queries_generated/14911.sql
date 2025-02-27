SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS cast_type,
    c.name AS company_name,
    mt.info AS movie_info
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON ci.movie_id = t.id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name c ON c.id = mc.company_id
JOIN 
    company_type ct ON ct.id = mc.company_type_id
JOIN 
    movie_info mi ON mi.movie_id = t.id
JOIN 
    info_type it ON it.id = mi.info_type_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
