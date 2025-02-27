SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ci.note AS role_note,
    ti.info AS additional_info,
    k.keyword AS movie_keyword,
    c.name AS company_name
FROM 
    aka_title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON ci.id = cc.subject_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
ORDER BY 
    t.production_year, a.name;
