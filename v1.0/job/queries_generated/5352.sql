SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    kt.keyword AS movie_keyword,
    pi.info AS actor_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    t.production_year > 2000
AND 
    c.kind = 'Distributor'
AND 
    pi.info_type_id IS NOT NULL
ORDER BY 
    t.production_year DESC, a.name ASC;
