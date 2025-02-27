-- Performance Benchmarking Query
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS actor_role,
    p.info AS actor_info,
    c.kind AS company_type,
    COUNT(mk.keyword) AS keyword_count
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
GROUP BY 
    t.title, a.name, r.role, p.info, c.kind
ORDER BY 
    t.title, a.name;
