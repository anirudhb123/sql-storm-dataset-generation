SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    c.role_id AS role_id,
    k.keyword AS movie_keyword,
    ci.kind AS company_type,
    ti.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON mc.movie_id = m.id
JOIN 
    company_type ci ON mc.company_type_id = ci.id
JOIN 
    movie_info mi ON mi.movie_id = m.id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    m.production_year >= 2000
    AND c.nr_order < 5
    AND k.keyword LIKE '%action%'
ORDER BY 
    a.name, m.title;
