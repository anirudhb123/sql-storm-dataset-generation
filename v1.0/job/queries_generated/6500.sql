SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id AS role_id,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    ct.kind AS company_type,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
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
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
    AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
    AND t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
