-- Query to benchmark performance of joins across the Join Order Benchmark schema
SELECT 
    a.id AS aka_name_id,
    a.name AS aka_name,
    t.id AS title_id,
    t.title AS title_name,
    c.id AS cast_info_id,
    c.nr_order AS cast_order,
    p.id AS person_info_id,
    p.info AS person_info,
    m.id AS movie_info_id,
    m.info AS movie_info,
    k.id AS keyword_id,
    k.keyword AS keyword_name
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL
ORDER BY 
    t.production_year DESC, 
    c.nr_order ASC;
