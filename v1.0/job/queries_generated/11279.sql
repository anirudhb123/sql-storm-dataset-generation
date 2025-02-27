-- Perform a benchmark measurement by joining multiple tables from the Join Order Benchmark schema
SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS actor_name,
    c.kind AS role_type,
    c.nr_order AS cast_order
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    company_name cn ON m.note LIKE '%' || cn.name || '%'
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, 
    c.nr_order;
