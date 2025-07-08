SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    ci.nr_order AS cast_order,
    comp.name AS company_name,
    k.keyword AS movie_keyword,
    mi.info AS movie_info,
    rt.role AS role_name
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND comp.country_code = 'USA'
ORDER BY 
    t.title, ci.nr_order;
