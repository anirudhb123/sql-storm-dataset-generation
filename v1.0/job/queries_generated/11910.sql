-- Performance benchmarking query to retrieve movie details along with cast and company information

SELECT 
    t.title AS movie_title,
    t.production_year,
    a.name AS actor_name,
    c.name AS company_name,
    ct.kind AS company_type
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, t.title;
