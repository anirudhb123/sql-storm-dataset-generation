SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS character_name,
    c.kind AS company_type,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year, r.role, c.kind
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    t.production_year DESC, actor_name ASC;
