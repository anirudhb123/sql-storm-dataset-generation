-- Performance Benchmarking Query
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ci.nr_order AS actor_order,
    g.kind AS genre,
    c.name AS company_name,
    mi.info AS movie_info
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON at.movie_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    kind_type g ON t.kind_id = g.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    t.title, 
    ci.nr_order;
