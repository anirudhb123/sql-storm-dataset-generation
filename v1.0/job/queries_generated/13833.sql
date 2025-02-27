-- SQL Query for Performance Benchmarking using Join Order Benchmark Schema
SELECT 
    a.id AS aka_name_id,
    a.name AS aka_name,
    t.id AS title_id,
    t.title AS title,
    c.id AS cast_info_id,
    c.note AS cast_note,
    p.id AS person_info_id,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON a.person_id = p.person_id
ORDER BY 
    t.production_year DESC, a.name;
