
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_type,
    mc.company_type_id,
    COUNT(*) AS total_roles
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    t.production_year >= 2000
    AND ct.kind = 'Distributor'
GROUP BY 
    a.name, t.title, c.kind, mc.company_type_id
HAVING 
    COUNT(*) > 1
ORDER BY 
    total_roles DESC, a.name ASC;
