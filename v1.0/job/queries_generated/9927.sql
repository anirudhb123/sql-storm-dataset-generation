SELECT 
    a.id AS alias_id,
    a.name AS alias_name,
    t.title AS movie_title,
    ci.nr_order AS cast_order,
    c.name AS company_name,
    k.keyword AS movie_keyword,
    i.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type i ON mi.info_type_id = i.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
WHERE 
    t.production_year >= 2000 
    AND k.keyword IS NOT NULL
ORDER BY 
    t.production_year DESC, 
    a.name ASC, 
    ci.nr_order ASC
LIMIT 100;
