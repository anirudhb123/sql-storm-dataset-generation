SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.nr_order AS cast_order,
    ct.kind AS cast_type,
    kc.keyword AS movie_keyword,
    ci.name AS company_name,
    mi.info AS movie_info
FROM 
    title t
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kc ON mk.keyword_id = kc.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name ci ON mc.company_id = ci.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    kind_type kt ON t.kind_id = kt.id
JOIN 
    role_type rt ON c.role_id = rt.id
JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    t.production_year > 2000
    AND a.name IS NOT NULL
    AND kc.keyword LIKE '%action%'
ORDER BY 
    t.production_year DESC, 
    a.name, 
    c.nr_order;
