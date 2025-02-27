SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    c.kind AS company_type,
    pi.info AS person_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    t.production_year >= 2000 
    AND ct.kind = 'Distributor'
    AND pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
ORDER BY 
    t.production_year DESC, 
    ak.name ASC;
