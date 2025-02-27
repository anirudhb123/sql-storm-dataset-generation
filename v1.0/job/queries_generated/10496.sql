SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    cn.name AS company_name,
    k.keyword AS movie_keyword,
    rt.role AS role_type,
    pi.info AS person_info,
    ti.kind AS title_kind
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type rt ON c.role_id = rt.id
JOIN 
    person_info pi ON a.person_id = pi.person_id
JOIN 
    kind_type ti ON t.kind_id = ti.id
ORDER BY 
    t.production_year DESC, a.name;
