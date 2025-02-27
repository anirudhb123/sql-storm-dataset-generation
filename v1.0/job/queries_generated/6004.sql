EXPLAIN ANALYZE 
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    p.info AS actor_info,
    c.kind AS cast_type,
    k.keyword AS movie_keyword,
    comp.name AS production_company,
    ti.info AS movie_info
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info ti ON t.id = ti.movie_id
WHERE 
    t.production_year > 2000 
    AND comp.country_code = 'USA'
    AND k.keyword LIKE '%action%'
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
