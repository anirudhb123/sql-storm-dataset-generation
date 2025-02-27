SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    r.role AS actor_role,
    k.keyword AS movie_keyword,
    c.name AS company_name,
    ci.kind AS company_type,
    pi.info AS person_info
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    title m ON ci.movie_id = m.id 
JOIN 
    role_type r ON ci.role_id = r.id 
JOIN 
    movie_keyword mk ON m.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    movie_companies mc ON m.id = mc.movie_id 
JOIN 
    company_name c ON mc.company_id = c.id 
JOIN 
    company_type ct ON mc.company_type_id = ct.id 
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id 
ORDER BY 
    m.production_year DESC, a.name;
