SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    m.info AS movie_info,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    i.info AS additional_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    person_info pi ON a.id = pi.person_id
JOIN 
    info_type it ON pi.info_type_id = it.id
WHERE 
    t.production_year >= 2000 
    AND k.keyword LIKE '%action%'
    AND m.info_type_id = (SELECT id FROM info_type WHERE info='Budget')
ORDER BY 
    t.production_year DESC, a.name;
