SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_kind,
    p.info AS actor_info,
    k.keyword AS movie_keyword,
    cn.name AS company_name,
    ti.info AS additional_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    t.production_year > 2000
    AND a.name IS NOT NULL
    AND k.keyword IS NOT NULL
ORDER BY 
    t.production_year DESC, a.name;
