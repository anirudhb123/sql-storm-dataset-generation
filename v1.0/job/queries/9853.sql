SELECT 
    t.title AS movie_title,
    p.name AS actor_name,
    c.kind AS company_type,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND c.kind LIKE '%Productions%'
    AND m.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Budget%')
ORDER BY 
    t.production_year DESC, 
    p.name ASC;
