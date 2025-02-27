SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS cast_note,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    ci.kind AS company_type,
    ti.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type ci ON mc.company_type_id = ci.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    person_info p ON cc.subject_id = p.person_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    t.production_year > 2000
AND 
    a.name ILIKE 'J%'
ORDER BY 
    t.production_year DESC, a.name;
