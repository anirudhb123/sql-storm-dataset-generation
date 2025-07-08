SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    g.kind AS genre,
    c.name AS company_name,
    i.info AS movie_info
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    kind_type g ON t.kind_id = g.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
WHERE 
    a.name ILIKE '%Smith%'
    AND t.production_year > 2000
ORDER BY 
    a.name, t.production_year DESC
LIMIT 10;
