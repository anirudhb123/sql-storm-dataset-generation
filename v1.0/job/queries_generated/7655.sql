SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    r.role AS role_type,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
    COUNT(DISTINCT mv.id) AS movie_count
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
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
GROUP BY 
    a.name, t.title, c.kind, r.role
HAVING 
    COUNT(DISTINCT t.id) > 5
ORDER BY 
    movie_count DESC;
