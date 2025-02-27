-- Performance Benchmarking Query for Join Order Benchmark Schema

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_type,
    ci.note AS cast_note
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    role_type c ON ci.role_id = c.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    a.name, t.production_year DESC;
