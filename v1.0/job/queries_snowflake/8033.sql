SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    r.role AS role,
    mi.info AS movie_info,
    k.keyword AS movie_keyword,
    COUNT(*) AS total_roles
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    person_info pi ON a.person_id = pi.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name LIKE 'A%' 
    AND t.production_year > 2000 
    AND c.kind = 'Production'
GROUP BY 
    a.name, t.title, c.kind, r.role, mi.info, k.keyword
ORDER BY 
    total_roles DESC, a.name ASC;
