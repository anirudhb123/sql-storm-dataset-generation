SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS character_role,
    m.country_code AS production_country,
    k.keyword AS genre,
    mi.info AS additional_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name ASC
LIMIT 100;
