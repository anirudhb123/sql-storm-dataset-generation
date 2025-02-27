SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    ti.info AS movie_info,
    kt.keyword AS movie_keyword
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
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year > 2000
    AND c.kind = 'Distributor'
ORDER BY 
    actor_name, movie_title;
