EXPLAIN ANALYZE 
SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    cn.name AS company_name,
    k.keyword AS movie_keyword,
    ti.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    a.name IS NOT NULL
AND 
    t.production_year BETWEEN 2000 AND 2020
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
