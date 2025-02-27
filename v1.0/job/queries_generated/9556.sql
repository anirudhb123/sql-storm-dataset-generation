SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.role_id AS role_id, 
    tc.kind AS company_type, 
    ci.info AS movie_info, 
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
GROUP BY 
    a.name, t.title, c.role_id, ct.kind, ci.info
HAVING 
    COUNT(DISTINCT kw.id) > 1 
ORDER BY 
    t.production_year DESC, a.name ASC;
