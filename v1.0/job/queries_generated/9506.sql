SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ci.nr_order AS actor_order,
    ct.kind AS cast_type,
    c.name AS company_name,
    mt.kind AS company_type,
    k.keyword AS movie_keyword,
    mi.info AS movie_info
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
    company_name c ON mc.company_id = c.id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
    AND ci.nr_order IS NOT NULL
    AND k.keyword IS NOT NULL
ORDER BY 
    t.production_year DESC, a.name, t.title;
