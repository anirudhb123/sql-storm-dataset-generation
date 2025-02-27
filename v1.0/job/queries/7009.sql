SELECT 
    a.id AS aka_id,
    a.name AS person_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    pi.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography' LIMIT 1)
WHERE 
    t.production_year >= 2000
    AND k.keyword LIKE '%action%'
ORDER BY 
    t.production_year DESC, a.name;
