EXPLAIN ANALYZE
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    cn.name AS company_name,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name ILIKE '%Smith%'
    AND t.production_year > 2000
    AND cn.country_code = 'USA'
ORDER BY 
    t.production_year DESC, a.name;
