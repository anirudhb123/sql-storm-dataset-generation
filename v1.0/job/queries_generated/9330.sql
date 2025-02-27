SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    c.kind AS cast_type, 
    m.name AS company_name, 
    mi.info AS movie_info, 
    k.keyword AS movie_keyword 
FROM 
    aka_title t 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    cast_info ci ON cc.subject_id = ci.id 
JOIN 
    aka_name a ON ci.person_id = a.person_id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name m ON mc.company_id = m.id 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
JOIN 
    keyword k ON t.id = k.movie_id 
WHERE 
    t.production_year > 2000 
    AND m.country_code = 'USA' 
    AND k.keyword LIKE '%action%' 
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
