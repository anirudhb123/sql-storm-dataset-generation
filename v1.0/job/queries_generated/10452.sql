-- Performance Benchmarking Query for Join Order Benchmark schema

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS role_note,
    t.production_year,
    t.kind_id
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    title tt ON t.id = tt.id
JOIN 
    movie_info mi ON tt.id = mi.movie_id
WHERE 
    tt.production_year >= 2000
    AND a.name IS NOT NULL
ORDER BY 
    t.production_year DESC, 
    a.name;
