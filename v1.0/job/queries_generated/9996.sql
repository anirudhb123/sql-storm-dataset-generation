SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS cast_type,
    ci.note AS cast_note,
    r.role AS role_type,
    k.keyword AS movie_keyword,
    c.name AS company_name,
    ci.nr_order AS actor_order,
    mi.info AS movie_info
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000 AND 
    c.country_code = 'USA' AND 
    mk.id IS NOT NULL
ORDER BY 
    t.title, a.name, ci.nr_order;
