-- SQL query for performance benchmarking using the Join Order Benchmark schema

SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role,
    mk.keyword AS keyword,
    ci.note AS cast_note
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    aka_name a ON cc.subject_id = a.person_id
JOIN 
    cast_info ci ON a.id = ci.person_id AND t.id = ci.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
