SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.role_id,
    k.keyword AS movie_keyword,
    cn.name AS company_name,
    inf.info AS additional_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type inf_t ON mi.info_type_id = inf_t.id
LEFT JOIN 
    movie_info_idx inf ON t.id = inf.movie_id AND inf_t.info = 'Director'
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND a.name LIKE 'J%' 
ORDER BY 
    t.production_year DESC, 
    a.name;
