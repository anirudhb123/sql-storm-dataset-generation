SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    pi.info AS person_info
FROM 
    title t
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    person_info pi ON a.person_id = pi.person_id
JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary')
    AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
ORDER BY 
    t.production_year DESC, 
    a.name;
