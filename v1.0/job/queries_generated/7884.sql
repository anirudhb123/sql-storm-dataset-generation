SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    tc.kind AS company_type, 
    k.keyword AS movie_keyword, 
    pi.info AS actor_info 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    movie_companies mc ON mc.movie_id = t.id 
JOIN 
    company_name cn ON cn.id = mc.company_id 
JOIN 
    company_type ct ON ct.id = mc.company_type_id 
JOIN 
    movie_keyword mk ON mk.movie_id = t.id 
JOIN 
    keyword k ON k.id = mk.keyword_id 
JOIN 
    person_info pi ON pi.person_id = a.person_id 
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
    AND ct.kind ILIKE '%producer%'
    AND k.keyword ILIKE '%action%' 
ORDER BY 
    t.production_year DESC, 
    a.name ASC 
LIMIT 50;
