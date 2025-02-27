SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_type,
    ct.kind AS company_type,
    COUNT(mk.keyword) AS keyword_count
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
GROUP BY 
    t.title, a.name, c.kind, ct.kind
ORDER BY 
    t.title, a.name;
