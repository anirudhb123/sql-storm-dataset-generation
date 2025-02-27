SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_role,
    m.info AS movie_info,
    k.keyword AS movie_keyword,
    cm.name AS company_name,
    ct.kind AS company_type
FROM 
    aka_title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
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
    company_name cm ON mc.company_id = cm.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    t.production_year >= 2000 
AND 
    a.surname_pcode IS NOT NULL 
AND 
    m.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%box office%')
ORDER BY 
    t.production_year DESC, a.name;
