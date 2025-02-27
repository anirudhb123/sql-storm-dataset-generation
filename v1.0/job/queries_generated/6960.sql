SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    r.role AS character_name,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    ti.info AS movie_info,
    ti2.info AS additional_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    movie_info_idx ti ON t.id = ti.movie_id
LEFT JOIN 
    movie_info_idx ti2 ON t.id = ti2.movie_id AND ti2.info_type_id <> ti.info_type_id
WHERE 
    a.name IS NOT NULL
    AND t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name, 
    t.title;
