SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    mi.info AS movie_info,
    ti.kind AS title_kind
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type cct ON ci.person_role_id = cct.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    kind_type ti ON t.kind_id = ti.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
    AND ci.nr_order = 1
ORDER BY 
    t.production_year DESC, a.name;
