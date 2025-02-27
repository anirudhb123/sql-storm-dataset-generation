-- Performance Benchmarking Query for Join Order Benchmark Schema

SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    c.kind AS character_type, 
    m.note AS production_note, 
    k.keyword AS movie_keyword 
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND cn.country_code = 'USA'
ORDER BY 
    t.production_year ASC, 
    a.name ASC;
