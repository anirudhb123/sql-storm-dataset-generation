SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.nr_order AS cast_order,
    k.keyword AS movie_keyword,
    cn.name AS company_name,
    ti.info AS movie_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND k.keyword LIKE '%action%'
ORDER BY 
    t.production_year DESC, 
    a.name, 
    c.nr_order;
