SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_type,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
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
    movie_info m ON t.id = m.movie_id
WHERE 
    m.info_type_id IN (SELECT id FROM info_type WHERE info = 'Plot')
    AND t.production_year BETWEEN 2000 AND 2023
ORDER BY 
    t.production_year DESC, a.name;
