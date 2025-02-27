SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role,
    kc.keyword AS keyword,
    ci.note AS company_note,
    pi.info AS person_info,
    t.production_year
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kc ON mk.keyword_id = kc.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND kc.keyword LIKE '%action%'
    AND co.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    a.name;
