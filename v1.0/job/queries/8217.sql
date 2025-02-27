SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    k.keyword AS movie_keyword,
    cn.name AS company_name,
    ct.kind AS company_type,
    ti.info AS movie_info,
    rt.role AS role
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
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    person_info pi ON cc.subject_id = pi.person_id
JOIN 
    info_type ti ON pi.info_type_id = ti.id
JOIN 
    role_type rt ON c.role_id = rt.id
WHERE 
    t.production_year >= 2000
AND 
    k.keyword = 'Action'
ORDER BY 
    t.production_year DESC, a.name;
