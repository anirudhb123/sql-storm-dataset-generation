SELECT 
    a.name AS actor_name, 
    m.title AS movie_title, 
    c.kind AS company_type, 
    k.keyword AS keyword, 
    pi.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.movie_id
JOIN 
    movie_companies mc ON m.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    m.production_year > 2000
    AND c.kind NOT IN ('Distributor', 'TV Network')
ORDER BY 
    a.name, m.title, c.kind;
