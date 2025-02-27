SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_type,
    ci.note AS role_note,
    ti.info AS additional_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year > 2000
    AND c.kind IS NOT NULL
    AND it.info LIKE '%award%'
ORDER BY 
    t.title, a.name;
