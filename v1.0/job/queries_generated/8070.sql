SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    r.role AS role_type,
    t.production_year,
    COUNT(mk.keyword) AS keyword_count,
    GROUP_CONCAT(mk.keyword) AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, ct.kind, r.role, t.production_year
HAVING 
    COUNT(mk.keyword) > 0
ORDER BY 
    t.production_year DESC, a.name ASC;
