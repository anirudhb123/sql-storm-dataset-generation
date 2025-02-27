SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    ct.kind AS company_type, 
    k.keyword AS keyword_used, 
    pi.info AS person_info, 
    ti.info AS movie_info 
FROM 
    title t 
JOIN 
    cast_info ci ON t.id = ci.movie_id 
JOIN 
    aka_name a ON ci.person_id = a.person_id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_type ct ON mc.company_type_id = ct.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id 
LEFT JOIN 
    movie_info ti ON t.id = ti.movie_id 
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND k.keyword LIKE '%action%' 
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
