SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    c.kind AS cast_type,
    ct.kind AS company_type,
    k.keyword AS movie_keyword,
    ti.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.movie_id
JOIN 
    movie_companies mc ON mc.movie_id = m.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON mk.movie_id = m.id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON mi.movie_id = m.id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    a.name LIKE '%Smith%'
    AND m.production_year BETWEEN 2000 AND 2020
    AND ct.kind IN ('Distributor', 'Production Company')
ORDER BY 
    m.production_year DESC, 
    a.name ASC;
