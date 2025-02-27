SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    g.kind AS genre,
    c.name AS company_name,
    ci.note AS cast_note
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    kind_type g ON t.kind_id = g.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND g.kind IN ('Drama', 'Comedy')
ORDER BY 
    t.production_year DESC, 
    a.name;
