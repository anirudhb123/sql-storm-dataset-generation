SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_type,
    c.nr_order AS role_order,
    co.name AS company_name,
    m.info AS movie_info,
    k.keyword AS movie_keyword,
    p.info AS person_info,
    a.id AS actor_id,
    t.production_year AS production_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000
AND 
    c.person_role_id IN (SELECT id FROM role_type WHERE role = 'Actor')
ORDER BY 
    t.production_year DESC, a.name;
