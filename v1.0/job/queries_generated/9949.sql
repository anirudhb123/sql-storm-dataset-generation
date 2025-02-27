SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    ci.nm_order AS cast_order,
    ct.kind AS cast_type,
    c.name AS company_name,
    mt.kind AS company_type,
    mi.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
JOIN 
    movie_info mi ON t.movie_id = mi.movie_id
JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year > 2000 
ORDER BY 
    t.production_year DESC, 
    actor_name ASC;
