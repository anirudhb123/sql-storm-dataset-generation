SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    pi.info AS person_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id AND ci.person_id = cc.subject_id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id 
JOIN 
    company_name cn ON cn.id = mc.company_id
JOIN 
    company_type c ON c.id = mc.company_type_id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    person_info pi ON pi.person_id = a.person_id
WHERE 
    t.production_year > 2000 AND 
    k.keyword LIKE '%action%' AND 
    c.kind = 'Production'
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
