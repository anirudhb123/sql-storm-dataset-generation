SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_kind,
    kc.keyword AS movie_keyword,
    tc.kind AS company_type
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kc ON mk.keyword_id = kc.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    c.kind LIKE 'actor%'
AND 
    t.production_year BETWEEN 2000 AND 2023
ORDER BY 
    t.production_year DESC, 
    a.name;
