SELECT 
    a.name AS actor_name, 
    t.title AS movie_title,
    c.role_id AS role_id, 
    ct.kind AS company_type, 
    m.production_year AS movie_year,
    k.keyword AS movie_keyword
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000 
    AND ct.kind LIKE 'Distributor%'
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE 'Box Office%')
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
