SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS character_name,
    p.info AS person_info,
    m.info AS movie_info,
    k.keyword AS movie_keyword,
    cc.kind AS company_type,
    ca.name AS company_name
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    char_name c ON ci.person_role_id = c.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name ca ON mc.company_id = ca.id
JOIN 
    company_type cc ON mc.company_type_id = cc.id
WHERE 
    t.production_year >= 2000 AND
    a.name IS NOT NULL AND
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
ORDER BY 
    t.production_year DESC, a.name;
