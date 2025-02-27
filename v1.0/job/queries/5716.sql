SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    p.info AS person_info,
    c.kind AS company_type,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title m ON ci.movie_id = m.id
JOIN 
    movie_companies mc ON m.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    m.production_year >= 2000
    AND c.kind = 'Distributor'
    AND k.keyword LIKE '%Action%'
ORDER BY 
    a.name, m.title;
