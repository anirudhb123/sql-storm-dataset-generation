SELECT 
    a.name AS actor_name, 
    m.title AS movie_title, 
    c.nr_order AS cast_order, 
    p.info AS person_info, 
    k.keyword AS movie_keyword, 
    ct.kind AS company_type, 
    co.name AS company_name
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    complete_cast cc ON c.movie_id = cc.movie_id
JOIN 
    title m ON cc.movie_id = m.id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    m.production_year >= 2000 
    AND a.name IS NOT NULL 
    AND k.keyword IS NOT NULL
ORDER BY 
    m.production_year DESC, 
    c.nr_order ASC;
