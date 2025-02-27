SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS character_type,
    m.name AS company_name,
    mk.keyword AS movie_keyword,
    pii.info AS person_info
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    comp_cast_type ct ON ci.role_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    person_info pii ON ci.person_id = pii.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
