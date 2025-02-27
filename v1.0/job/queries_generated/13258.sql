-- Performance benchmarking query to analyze join performance across multiple tables in the Join Order Benchmark schema
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_type,
    m.note AS company_note,
    i.info AS movie_info
FROM 
    title t
JOIN 
    movie_companies m ON t.id = m.movie_id
JOIN 
    company_name cn ON m.company_id = cn.id
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_info i ON t.id = i.movie_id
WHERE 
    t.production_year >= 2000
    AND i.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
ORDER BY 
    t.production_year DESC, 
    a.name;
