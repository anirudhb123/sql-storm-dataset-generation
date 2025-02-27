-- Performance benchmarking query for Join Order Benchmark schema

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS character_note,
    r.role AS role_type,
    co.name AS company_name,
    m.info AS movie_info
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
    movie_info m ON t.id = m.movie_id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    a.name, t.production_year;
