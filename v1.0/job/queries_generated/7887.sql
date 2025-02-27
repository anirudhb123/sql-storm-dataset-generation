SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    p.info AS actor_info,
    k.keyword AS movie_keyword,
    c.name AS company_name,
    ct.kind AS company_type,
    ti.info AS movie_additional_info
FROM 
    aka_title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    t.production_year >= 2000 
    AND a.name IS NOT NULL 
    AND k.keyword IS NOT NULL
ORDER BY 
    t.production_year DESC, a.name;
