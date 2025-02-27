SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS cast_type,
    pc.info AS person_info,
    kc.keyword AS movie_keyword,
    c.name AS company_name,
    mi.info AS movie_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id 
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    comp_cast_type ct ON ct.id = ci.person_role_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword kc ON kc.id = mk.keyword_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.id
LEFT JOIN 
    company_name c ON c.id = mc.company_id
LEFT JOIN 
    person_info pc ON pc.person_id = a.person_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
