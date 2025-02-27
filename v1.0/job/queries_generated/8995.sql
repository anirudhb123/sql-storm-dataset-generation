SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    r.role AS role_name, 
    COUNT(mk.id) AS keyword_count, 
    COUNT(DISTINCT mc.company_id) AS company_count, 
    MIN(mi.info) AS first_info, 
    MAX(mi.info) AS last_info
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year BETWEEN 1990 AND 2023
GROUP BY 
    t.title, a.name, r.role
HAVING 
    COUNT(mk.id) > 5 
ORDER BY 
    keyword_count DESC, company_count DESC, movie_title ASC;
