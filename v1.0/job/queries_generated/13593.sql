-- Performance Benchmarking Query
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.nr_order AS cast_order,
    m.company_id,
    k.keyword AS movie_keyword,
    i.info AS movie_info
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info c ON at.movie_id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
ORDER BY 
    t.title, c.nr_order;
